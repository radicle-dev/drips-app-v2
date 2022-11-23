<script lang="ts">
  import tokens from '$lib/stores/tokens';
  import { page } from '$app/stores';
  import Token from '$lib/components/token/token.svelte';
  import Button from '$lib/components/button/button.svelte';
  import ArrowUp from 'radicle-design-system/icons/ArrowUp.svelte';
  import Plus from 'radicle-design-system/icons/Plus.svelte';
  import Minus from 'radicle-design-system/icons/Minus.svelte';
  import ArrowLeft from 'radicle-design-system/icons/ArrowLeft.svelte';
  import balances from '$lib/stores/balances';
  import Amount from '$lib/components/amount/amount.svelte';
  import TokenStat from '$lib/components/token-stat/token-stat.svelte';
  import Streams from '../../../dashboard/sections/streams.section.svelte';
  import Stepper from '$lib/components/stepper/stepper.svelte';
  import collectFlowSteps from '../../../dashboard/sections/collect-flow/collect-flow-steps';
  import modal from '$lib/stores/modal';
  import wallet from '$lib/stores/wallet';
  import guardConnected from '$lib/utils/guard-connected';

  const urlParamToken = $page.params.token.toLowerCase();

  $: token = $tokens?.find(
    (token) =>
      token.info.address.toLowerCase() === urlParamToken ||
      token.info.symbol.toLowerCase() === urlParamToken,
  );

  $: tokenAddress = token?.info.address ?? urlParamToken;

  $: userId = $wallet.dripsUserId;

  $: outgoingEstimate =
    userId && $balances.accounts[userId]
      ? $balances.accounts[userId][tokenAddress] ?? null
      : undefined;

  $: incomingTotals =
    userId && tokenAddress && $balances
      ? balances.getIncomingTokenAmountsByUser(userId, tokenAddress) ?? null
      : undefined;

  function openCollectModal() {
    modal.show(Stepper, undefined, collectFlowSteps(tokenAddress));
  }

  // redirect to connect page if disconnects
  $: {
    $wallet.connected;
    guardConnected();
  }
</script>

<article class="flex flex-col gap-16">
  <header>
    <div class="mb-5 flex">
      <a
        href="/app/dashboard"
        class="pl-2 py-1 pr-4 -ml-2 lg:-ml-9 rounded-full flex items-center typo-header-4 text-foreground-level-5 btn-theme-transparent"
      >
        <div class="w-8 h-8 flex items-center">
          <ArrowLeft />
        </div>
        Dashboard
      </a>
    </div>
    <h1>
      <Token address={tokenAddress} show="symbol" size="huge" fontSize="typo-header-1" />
    </h1>
  </header>

  <!-- balances -->
  <section class="grid sm:grid-cols-2 gap-3 lg:-mx-4">
    <h2 class="sr-only">Your Balances</h2>

    <TokenStat title="Incoming">
      <svelte:fragment slot="detail">
        {#if incomingTotals && incomingTotals.amountPerSecond !== 0n}
          <Amount
            amountPerSecond={{ tokenAddress, amount: incomingTotals.amountPerSecond }}
            showSymbol={false}
          />
        {/if}
      </svelte:fragment>

      <svelte:fragment slot="value">
        {#if incomingTotals === undefined}
          <span class="animate-pulse">...</span>
        {:else}
          {@const amount = incomingTotals.totalEarned ?? 0n}
          <span class:text-foreground-level-4={amount === 0n}>
            <Amount amount={{ tokenAddress, amount }} showSymbol={false} amountClasses="" />
          </span>
        {/if}
      </svelte:fragment>

      <svelte:fragment slot="actions">
        <div class="flex gap-3">
          <Button icon={ArrowUp} on:click={openCollectModal}>Collect</Button>
        </div>
      </svelte:fragment>
    </TokenStat>

    <TokenStat title="Outgoing">
      <svelte:fragment slot="detail">
        {#if outgoingEstimate}
          <Amount
            amountPerSecond={{
              tokenAddress,
              amount: -outgoingEstimate.totals.totalAmountPerSecond,
            }}
            showSymbol={false}
          />
        {/if}
      </svelte:fragment>

      <svelte:fragment slot="value">
        {#if outgoingEstimate === undefined}
          <span class="animate-pulse">...</span>
        {:else}
          {@const amount = outgoingEstimate ? outgoingEstimate.totals.remainingBalance : 0n}
          <span class:text-foreground-level-4={amount === 0n}>
            <Amount amount={{ tokenAddress, amount }} showSymbol={false} amountClasses="" />
          </span>
        {/if}
      </svelte:fragment>

      <svelte:fragment slot="actions">
        <div class="flex gap-1">
          <Button icon={Plus}>Add</Button>
          <Button icon={Minus}>Withdraw</Button>
        </div>
      </svelte:fragment>
    </TokenStat>
  </section>

  <Streams {userId} disableActions={false} {tokenAddress} />
</article>