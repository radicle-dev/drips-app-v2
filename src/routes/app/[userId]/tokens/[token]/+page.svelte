<script lang="ts">
  import tokens from '$lib/stores/tokens';
  import { page } from '$app/stores';
  import Token from '$lib/components/token/token.svelte';
  import Button from '$lib/components/button/button.svelte';
  import ArrowUp from 'radicle-design-system/icons/ArrowUp.svelte';
  import Plus from 'radicle-design-system/icons/Plus.svelte';
  import Minus from 'radicle-design-system/icons/Minus.svelte';
  import balances from '$lib/stores/balances';
  import Amount from '$lib/components/amount/amount.svelte';
  import TokenStat from '$lib/components/token-stat/token-stat.svelte';
  import Streams from '../../../dashboard/sections/streams.section.svelte';
  import Stepper from '$lib/components/stepper/stepper.svelte';
  import modal from '$lib/stores/modal';
  import wallet from '$lib/stores/wallet';
  import guardConnected from '$lib/utils/guard-connected';
  import checkIsUser from '$lib/utils/check-is-user';
  import decodeUserId from '$lib/utils/decode-user-id';
  import LargeEmptyState from '$lib/components/large-empty-state/large-empty-state.svelte';
  import collectFlowSteps from '$lib/flows/collect-flow/collect-flow-steps';
  import getWithdrawSteps from '$lib/flows/withdraw-flow/withdraw-flow-steps';
  import topUpFlowSteps from '$lib/flows/top-up-flow/top-up-flow-steps';
  import addCustomTokenFlowSteps from '$lib/flows/add-custom-token/add-custom-token-flow-steps';
  import { getAddress } from 'ethers/lib/utils';

  const urlParamToken = $page.params.token.toLowerCase();

  $: token = $tokens?.find(
    (token) =>
      token.info.address.toLowerCase() === urlParamToken.toLowerCase() ||
      token.info.symbol.toLowerCase() === urlParamToken.toLowerCase(),
  );

  $: tokenAddress = token?.info.address ?? urlParamToken;

  $: userId = $wallet.dripsUserId;

  $: outgoingEstimate =
    userId && $balances.accounts[userId]
      ? $balances.accounts[userId][getAddress(tokenAddress)] ?? null
      : undefined;

  $: incomingTotals =
    userId && tokenAddress && $balances
      ? balances.getIncomingTokenAmountsByUser(userId, tokenAddress) ?? null
      : undefined;

  function openCollectModal() {
    modal.show(Stepper, undefined, collectFlowSteps(tokenAddress));
  }

  function openAddFundsModal() {
    modal.show(Stepper, undefined, topUpFlowSteps(tokenAddress));
  }

  function openWithdrawModal() {
    modal.show(Stepper, undefined, getWithdrawSteps(tokenAddress));
  }

  let error: 'connected-to-wrong-user' | 'unknown-token' | undefined;

  async function checkUrlUserId() {
    const decodedUrlUserId = await decodeUserId($page.params.userId);

    const connectedToRightUser = checkIsUser(decodedUrlUserId.dripsUserId);
    if (!connectedToRightUser) return (error = 'connected-to-wrong-user');
    if (!token) return (error = 'unknown-token');
    error = undefined;
  }

  // redirect to connect page if disconnects
  $: {
    $wallet.connected;
    $tokens;
    if (guardConnected()) checkUrlUserId();
  }

  $: withdrawDisabled = !outgoingEstimate;
</script>

<svelte:head>
  <title>{token?.info.name ?? 'Unknown Token'} | Drips</title>
  <meta name="description" content="Drips Token Page" />
</svelte:head>

{#if error === 'connected-to-wrong-user'}
  <LargeEmptyState
    headline="Unable to view someone else's token page"
    description="Sorry, but you currently can only view your own token pages."
    emoji="????"
  />
{:else if error === 'unknown-token'}
  <LargeEmptyState
    headline="Unknown token"
    description="This token with address {tokenAddress} is not supported by default. You can manually add it to your custom tokens list."
    button={{
      handler: () => modal.show(Stepper, undefined, addCustomTokenFlowSteps(tokenAddress)),
      label: 'Add custom token',
    }}
    emoji="????"
  />
{:else}
  <article class="flex flex-col gap-16">
    <header class="flex gap-4 items-center">
      <Token address={tokenAddress} show="none" size="huge" fontSize="typo-header-1" />
      <div class="flex-col gap-2">
        <h1>
          {token?.info.name ?? 'Unknown token'}
        </h1>
        {#if token?.info.symbol}
          <h4 class="typo-text-mono-bold" style="color: var(--color-foreground-level-5)">
            {token.info.symbol}
          </h4>
        {/if}
      </div>
    </header>

    <!-- balances -->
    <section class="grid sm:grid-cols-2 gap-3">
      <h2 class="sr-only">Your Balances</h2>

      <TokenStat
        title="Incoming"
        tooltip="Your incoming balance is the cumulative total earned from any incoming streams for this token."
      >
        <svelte:fragment slot="detail">
          {#if incomingTotals && incomingTotals.amountPerSecond !== 0n}
            <Amount
              showSymbol={false}
              amountPerSecond={{ tokenAddress, amount: incomingTotals.amountPerSecond }}
            />
          {/if}
        </svelte:fragment>

        <svelte:fragment slot="value">
          {#if incomingTotals === undefined}
            <span class="animate-pulse">...</span>
          {:else}
            {@const amount = incomingTotals.totalEarned ?? 0n}
            <span class:text-foreground-level-4={amount === 0n}>
              <Amount showSymbol={false} amount={{ tokenAddress, amount }} amountClasses="" />
            </span>
          {/if}
        </svelte:fragment>

        <svelte:fragment slot="actions">
          <div class="flex gap-3">
            <Button icon={ArrowUp} on:click={openCollectModal}>Collect</Button>
          </div>
        </svelte:fragment>
      </TokenStat>

      <TokenStat
        title="Outgoing"
        tooltip="Your outgoing balance is the remaining balance you can stream to others for this token."
      >
        <svelte:fragment slot="detail">
          {#if outgoingEstimate}
            <Amount
              showSymbol={false}
              amountPerSecond={{
                tokenAddress,
                amount: -outgoingEstimate.totals.totalAmountPerSecond,
              }}
            />
          {/if}
        </svelte:fragment>

        <svelte:fragment slot="value">
          {#if outgoingEstimate === undefined}
            <span class="animate-pulse">...</span>
          {:else}
            {@const amount = outgoingEstimate ? outgoingEstimate.totals.remainingBalance : 0n}
            <span class:text-foreground-level-4={amount === 0n}>
              <Amount showSymbol={false} amount={{ tokenAddress, amount }} amountClasses="" />
            </span>
          {/if}
        </svelte:fragment>

        <svelte:fragment slot="actions">
          <div class="flex gap-2">
            <Button icon={Plus} on:click={openAddFundsModal}>Add</Button>
            <Button disabled={withdrawDisabled} icon={Minus} on:click={openWithdrawModal}
              >Withdraw</Button
            >
          </div>
        </svelte:fragment>
      </TokenStat>
    </section>

    <Streams {userId} disableActions={false} {tokenAddress} />
  </article>
{/if}
