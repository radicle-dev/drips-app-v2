#!/bin/bash
set -euo pipefail

check() {
  lsof -Pi :5432 -sTCP:LISTEN -t >/dev/null && echo "π½ Postgres DB appears to be upβ¦" || (echo "π Please ensure a Postgres DB is available at port 5432" && exit 1)
  lsof -Pi :5001 -sTCP:LISTEN -t >/dev/null&& echo "πͺ IPFS node appears to be upβ¦" || (echo "π Please ensure an IPFS node is available at port 5001" && exit 1)
}

setup() {
  pg_user=${PGUSER:-$(whoami)}
  pg_password=${PGPASSWORD:-postgres}
  pg_host=${PGHOST:-localhost}

  debug=${DEBUG:-false}

  # Create Graph Database
  echo "π½ Recreating graph-node database"
  psql -h $pg_host -U $pg_user -c 'DROP DATABASE IF EXISTS "graph-node"'
  psql -h $pg_host -U $pg_user -c 'CREATE DATABASE "graph-node"'
  echo "β Done"

  # Set env vars
  echo "π€ Setting env vars"
  cd ./src/e2e-tests/.tmp/
  cd ./drips-contracts
  source ./scripts/local-env.sh
  echo "β Done"

  # Start anvil
  echo "πΈ Starting a local Ethereum testnet with Anvil"
  output=$(mktemp "${TMPDIR:-/tmp/}$(basename $0).XXX")
  anvil &> $output &
  if [ "$debug" = true ]; then tail -f $output & fi
  server_pid=$!
  echo "β Anvil pid: $server_pid"
  echo "β Output: $output"
  echo "β³ Waiting for local Ethereum testnet to come onlineβ¦"
  until grep -q -i 'Listening on 127.0.0.1:8545' $output
  do
    if ! ps $server_pid > /dev/null 
    then
      echo "π Anvil died" >&2
      exit 1
    fi
    echo "β³ Still waitingβ¦"
    sleep 1
  done
  echo "β Local testnet is running!" 

  # Deploy Drips Contracts
  echo "π§ Deploying Drips Contracts"
  echo "yes" | ./scripts/deploy.sh
  echo "β Done"

  # Deploy mock ERC-20
  echo "π° Deploying Mock ERC-20"
  cd ../drips-contracts
  forge create $WALLET_ARGS ./lib/openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol:ERC20PresetFixedSupply --constructor-args "Testcoin" "TEST" 100000000000000000000 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
  echo "β Done"

  # Run graph node
  echo "π Running Graph Node"
  cd ../graph-node
  output=$(mktemp "${TMPDIR:-/tmp/}$(basename $0).XXX")
  echo "cargo run -p graph-node --release -- --postgres-url postgresql://$pg_user:$pg_password@$pg_host:5432/graph-node --ethereum-rpc goerli:all:http://localhost:8545 --ipfs localhost:5001" | /bin/bash &> $output &
  graph_pid=$!

  if [ "$debug" = true ]; then tail -f $output & fi

  echo "β Graph node pid: $graph_pid"
  echo "β Output: $output"
  echo "β³ Waiting for the Graph Node to compile & startβ¦"
  until grep -q -i 'Started all assigned subgraphs' $output
  do
    if ! ps $graph_pid > /dev/null 
    then
      echo "π Graph Node died" >&2
      exit 1
    fi
    echo "β³ Still waitingβ¦"
    sleep 1
  done
  echo 
  echo "β Graph node is running!" 

  # Deploy subgraph
  echo "Deploying Subgraph"
  cd ../drips-subgraph
  npm run create-local
  echo -e "\n" | npm run deploy-local

  background=${BACKGROUND:-false}

  if [ "$background" = true ]; then
    echo "Background mode. Keeping processes up and exiting."
    exit 0
  else
    read -p "βοΈ Test environment is ready for your E2E tests. Press enter to stop the test environment."

    echo "π§Ή Cleaning up processesβ¦"
    pkill -9 anvil
    pkill -9 graph-node

    echo "π Bye"
  fi
}

skip_check=${SKIP_CHECK:-false}

if [ "$skip_check" != true ]; then
  (check)
fi
(setup)
