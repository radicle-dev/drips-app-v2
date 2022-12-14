<script lang="ts">
  import TokensIcon from 'radicle-design-system/icons/Orgs.svelte';
  import SectionHeader from '$lib/components/section-header/section-header.svelte';
  import Table, { type RowClickEventPayload } from '$lib/components/table/table.svelte';
  import TokenCell, { type TokenCellData } from '$lib/components/table/cells/token.cell.svelte';
  import { getCoreRowModel, type ColumnDef, type TableOptions } from '@tanstack/svelte-table';
  import balances from '$lib/stores/balances/balances.store';
  import Amount, { type AmountCellData } from '$lib/components/table/cells/amount.cell.svelte';
  import SectionSkeleton from '$lib/components/section-skeleton/section-skeleton.svelte';
  import streams from '$lib/stores/streams';
  import modal from '$lib/stores/modal';
  import assert from '$lib/utils/assert';
  import ChevronRightCell from '$lib/components/table/cells/chevron-right-cell.svelte';
  import unreachable from '$lib/utils/unreachable';
  import { AddressDriverClient } from 'radicle-drips';
  import wallet from '$lib/stores/wallet';
  import Stepper from '$lib/components/stepper/stepper.svelte';
  import getTopUpFlowSteps from '$lib/flows/top-up-flow/top-up-flow-steps';
  import Plus from 'radicle-design-system/icons/Plus.svelte';
  import onClickGoto from '$lib/utils/on-click-goto';

  interface TokenTableRow {
    token: TokenCellData;
    earnings: AmountCellData;
    streaming: AmountCellData;
    netRate: AmountCellData;
  }

  export let userId: string | undefined;
  export let disableActions = true;

  $: accountEstimate = userId ? $balances.accounts[userId] : undefined;

  let tableData: TokenTableRow[] = [];

  function updateTable() {
    if (!$balances || !accountEstimate || !userId) {
      tableData = [];
      return;
    }

    const ownStreams = streams.getStreamsForUser(userId);

    let tokensToShow: string[] = [];

    tokensToShow.push(
      ...balances.getStreamEstimatesByReceiver(userId).map((se) => se.tokenAddress),
    );
    tokensToShow.push(...Object.keys(accountEstimate));
    tokensToShow.push(
      ...(ownStreams.incoming.map((stream) => stream.dripsConfig.amountPerSecond.tokenAddress) ??
        []),
    );
    tokensToShow = [...new Set(tokensToShow)];

    tableData = tokensToShow.map((tokenAddress) => {
      assert(userId);

      const estimate = accountEstimate?.[tokenAddress];
      const incomingTotals = balances.getIncomingTokenAmountsByUser(userId, tokenAddress);

      return {
        token: {
          address: tokenAddress,
        },
        earnings: {
          amount: {
            amount: incomingTotals.totalEarned,
            tokenAddress,
          },
          amountPerSecond: {
            amount: incomingTotals.amountPerSecond,
            tokenAddress,
          },
          showSymbol: false,
        },
        streaming: {
          amount: {
            tokenAddress,
            amount: estimate?.totals.remainingBalance ?? 0n,
          },
          amountPerSecond: {
            tokenAddress,
            amount: -(estimate?.totals.totalAmountPerSecond ?? 0n),
          },
          showSymbol: false,
        },
        netRate: {
          amountPerSecond: {
            amount: incomingTotals.amountPerSecond - (estimate?.totals.totalAmountPerSecond ?? 0n),
            tokenAddress,
          },
          showSymbol: false,
        },
      };
    });
  }

  $: {
    $balances;
    if (userId) updateTable();
  }

  function buildTableColumns(isClickable = false): ColumnDef<TokenTableRow>[] {
    return [
      {
        accessorKey: 'token',
        header: 'Token',
        cell: () => TokenCell,
        enableSorting: false,
        size: (100 / 24) * 8,
      },
      {
        accessorKey: 'earnings',
        header: 'Incoming',
        cell: () => Amount,
        enableSorting: false,
        size: (100 / 24) * 5,
        meta: {
          tooltipMessage:
            'Your incoming balance is the cumulative total earned from any incoming streams for this token.',
        },
      },
      {
        accessorKey: 'streaming',
        header: 'Outgoing',
        cell: () => Amount,
        enableSorting: false,
        size: (100 / 24) * 5,
        meta: {
          tooltipMessage:
            'Your outgoing balance is the remaining balance you can stream to others for this token.',
        },
      },
      {
        accessorKey: 'netRate',
        header: 'Net rate',
        cell: () => Amount,
        enableSorting: false,
        size: (100 / 24) * 2,
      },
      {
        accessorKey: 'chevron',
        header: '',
        cell: isClickable ? () => ChevronRightCell : undefined,
        enableSorting: false,
        size: (100 / 24) * 2,
      },
    ];
  }
  $: isMyBalances = userId === $wallet.dripsUserId;
  $: tableColumns = buildTableColumns(isMyBalances);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let options: TableOptions<any>;
  $: options = {
    data: tableData,
    columns: tableColumns,
    getCoreRowModel: getCoreRowModel(),
  };

  const { fetchStatuses } = streams;

  // As soon as the given account has been fetched at least once, display content.
  let loaded = false;
  $: if (userId && ['error', 'fetched'].includes($fetchStatuses[userId])) loaded = true;

  $: error = Boolean(userId && $fetchStatuses[userId] === 'error');

  function onRowClick(event: CustomEvent<RowClickEventPayload>) {
    // go to token page by address
    const tokenAddress = tableData[event.detail.rowIndex].token.address;
    assert(userId);
    const address = AddressDriverClient.getUserAddress(userId);
    onClickGoto(`/app/${address ?? unreachable()}/tokens/${tokenAddress}`, event.detail.event);
  }
</script>

<div class="section">
  <SectionHeader
    icon={TokensIcon}
    label="Balances"
    actionsDisabled={!accountEstimate}
    actions={disableActions
      ? []
      : [
          {
            handler: () => modal.show(Stepper, undefined, getTopUpFlowSteps()),
            icon: Plus,
            label: 'Add funds',
          },
        ]}
  />
  <div class="content">
    <SectionSkeleton
      horizontalScroll
      emptyStateHeadline="No tokens"
      emptyStateEmoji="????"
      emptyStateText="This is where any tokens balances you stream or earned show up."
      {loaded}
      {error}
      empty={tableData.length === 0}
    >
      <Table {options} rowHeight={76} isRowClickable={isMyBalances} on:rowClick={onRowClick} />
    </SectionSkeleton>
  </div>
</div>

<style>
  .section {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }
</style>
