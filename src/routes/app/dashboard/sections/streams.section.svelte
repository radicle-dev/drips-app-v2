<script lang="ts">
  import TokenStreamIcon from 'radicle-design-system/icons/TokenStreams.svelte';
  import PlusIcon from 'radicle-design-system/icons/Plus.svelte';

  import SectionHeader from '$lib/components/section-header/section-header.svelte';
  import Table from '$lib/components/table/table.svelte';
  import { getCoreRowModel, type ColumnDef, type TableOptions } from '@tanstack/svelte-table';
  import Amount, { type AmountCellData } from '$lib/components/table/cells/amount.cell.svelte';
  import streams from '$lib/stores/streams/streams.store';
  import IdentityBadgeCell from '$lib/components/table/cells/identity-badge.cell.svelte';
  import balancesStore from '$lib/stores/balances/balances.store';
  import SectionSkeleton from '$lib/components/section-skeleton/section-skeleton.svelte';
  import modal from '$lib/stores/modal';
  import Stepper from '$lib/components/stepper/stepper.svelte';
  import { makeStep } from '$lib/components/stepper/types';
  import InputDetails from './create-stream-flow/input-details.svelte';
  import balances from '$lib/stores/balances';
  import SuccessStep from '$lib/components/success-step/success-step.svelte';

  interface OutgoingStreamTableRow {
    name: string;
    toAddress: string;
    amount: AmountCellData;
  }

  interface IncomingStreamTableRow {
    name: string;
    fromAddress: string;
    amount: AmountCellData;
  }

  let outgoingTableData: OutgoingStreamTableRow[] = [];
  let incomingTableData: IncomingStreamTableRow[] = [];

  function updateTable() {
    outgoingTableData = ($streams.ownStreams?.outgoing ?? []).map((stream) => ({
      name: stream.name ?? 'Unnamed stream',
      toAddress: stream.receiver.address,
      amount: {
        amount: {
          amount: balances.getEstimateByStreamId(stream.id)?.totalStreamed ?? 0n,
          tokenAddress: stream.dripsConfig.amountPerSecond.tokenAddress,
        },
        amountPerSecond: stream.dripsConfig.amountPerSecond,
      },
    }));

    incomingTableData = ($streams.ownStreams?.incoming ?? []).map((stream) => ({
      name: stream.name ?? 'Unnamed stream',
      fromAddress: stream.sender.address,
      amount: {
        amountPerSecond: stream.dripsConfig.amountPerSecond,
        amount: {
          amount: balances.getEstimateByStreamId(stream.id)?.totalStreamed ?? 0n,
          tokenAddress: stream.dripsConfig.amountPerSecond.tokenAddress,
        },
      },
    }));
  }

  $: {
    $streams.ownStreams;
    $balancesStore;
    updateTable();
  }

  const outgoingTableColumns: ColumnDef<OutgoingStreamTableRow>[] = [
    {
      accessorKey: 'name',
      header: 'Name',
      cell: (info) => info.getValue(),
      enableSorting: false,
    },
    {
      accessorKey: 'toAddress',
      header: 'To',
      cell: () => IdentityBadgeCell,
      enableSorting: false,
    },
    {
      accessorKey: 'amount',
      header: 'Amount streamed',
      cell: () => Amount,
      enableSorting: false,
    },
  ];

  const incomingTableColumns: ColumnDef<OutgoingStreamTableRow>[] = [
    {
      accessorKey: 'name',
      header: 'Name',
      cell: (info) => info.getValue(),
      enableSorting: false,
    },
    {
      accessorKey: 'fromAddress',
      header: 'From',
      cell: () => IdentityBadgeCell,
      enableSorting: false,
    },
    {
      accessorKey: 'amount',
      header: 'Amount earned',
      cell: () => Amount,
      enableSorting: false,
    },
  ];

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let optionsOutgoing: TableOptions<any>;
  $: optionsOutgoing = {
    data: outgoingTableData,
    columns: outgoingTableColumns,
    getCoreRowModel: getCoreRowModel(),
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let optionsIncoming: TableOptions<any>;
  $: optionsIncoming = {
    data: incomingTableData,
    columns: incomingTableColumns,
    getCoreRowModel: getCoreRowModel(),
  };

  $: loaded = $streams.ownStreams !== undefined && Object.keys($balancesStore.accounts).length > 0;
</script>

<div class="section">
  <SectionHeader
    icon={TokenStreamIcon}
    label="Streams"
    actionsDisabled={!loaded}
    actions={[
      {
        handler: () => {
          modal.show(Stepper, undefined, {
            steps: [
              makeStep({
                component: InputDetails,
                props: undefined,
              }),
              makeStep({
                component: SuccessStep,
                props: {
                  message:
                    'Your stream has been successfully created. ' +
                    'Please note that it may take a while for your dashboard to update.',
                },
              }),
            ],
          });
        },
        icon: PlusIcon,
        label: 'Create stream',
      },
    ]}
  />
  <div class="content">
    <SectionSkeleton
      emptyStateEmoji="🫙"
      emptyStateHeadline="No streams"
      emptyStateText="This is where incoming and outgoing streams for your account will appear."
      {loaded}
      empty={$streams.ownStreams?.incoming.length === 0 &&
        $streams.ownStreams?.outgoing.length === 0}
    >
      {#if optionsOutgoing.data.length > 0}
        <div class="table-container">
          <h4 class="table-group-header">↑ Outgoing</h4>
          <Table options={optionsOutgoing} />
        </div>
      {/if}
      {#if optionsIncoming.data.length > 0}
        <div class="table-container">
          <h4 class="table-group-header">↓ Incoming</h4>
          <Table options={optionsIncoming} />
        </div>
      {/if}
    </SectionSkeleton>
  </div>
</div>

<style>
  .section {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .content {
    margin: 0 -1rem 0 -1rem;
    overflow-y: scroll;
  }

  .table-container {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .table-container:first-child:not(:last-child) {
    margin-bottom: 2rem;
  }

  .table-group-header {
    color: var(--color-foreground-level-6);
    margin-left: calc(0.75rem + 2px);
  }

  @media (max-width: 1024px) {
    .content {
      padding: 0 1rem 0 1rem;
    }

    .table-group-header {
      margin-left: none;
    }
  }
</style>