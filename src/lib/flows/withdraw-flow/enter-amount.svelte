<script lang="ts">
  import Button from '$lib/components/button/button.svelte';
  import EmojiAndToken from '$lib/components/emoji-and-token/emoji-and-token.svelte';
  import FormField from '$lib/components/form-field/form-field.svelte';
  import ListSelect from '$lib/components/list-select/list-select.svelte';
  import StepHeader from '$lib/components/step-header/step-header.svelte';
  import StepLayout from '$lib/components/step-layout/step-layout.svelte';
  import Token from '$lib/components/token/token.svelte';
  import balances from '$lib/stores/balances';
  import streams from '$lib/stores/streams';
  import tokens from '$lib/stores/tokens';
  import wallet from '$lib/stores/wallet';
  import formatTokenAmount from '$lib/utils/format-token-amount';
  import { getAddressDriverClient } from '$lib/utils/get-drips-clients';
  import unreachable from '$lib/utils/unreachable';
  import { parseUnits } from 'ethers/lib/utils';
  import type { TextInputValidationState } from 'radicle-design-system/TextInput';
  import TextInput from 'radicle-design-system/TextInput.svelte';
  import { constants } from 'radicle-drips';
  import type { Writable } from 'svelte/store';
  import assert from '$lib/utils/assert';
  import type { WithdrawFlowState } from './withdraw-flow-state';
  import type { StepComponentEvents, UpdateAwaitStepFn } from '$lib/components/stepper/types';
  import Emoji from 'radicle-design-system/Emoji.svelte';
  import expect from '$lib/utils/expect';
  import { createEventDispatcher } from 'svelte';
  import etherscanLink from '$lib/utils/etherscan-link';

  const dispatch = createEventDispatcher<StepComponentEvents>();

  export let context: Writable<WithdrawFlowState>;

  $: tokenInfo = tokens.getByAddress($context.tokenAddress) ?? unreachable();
  $: estimate =
    $balances.streamable.find((amount) => amount.tokenAddress === $context.tokenAddress) ??
    unreachable();

  let amount: number;
  $: amountWei = amount
    ? parseUnits(String(amount), tokenInfo.info.decimals).toBigInt()
    : undefined;

  let validationState: TextInputValidationState;
  $: {
    if (amountWei && amountWei > 0n) {
      if (amountWei * BigInt(constants.AMT_PER_SEC_MULTIPLIER) < estimate.amount) {
        validationState = { type: 'valid' };
      } else {
        validationState = {
          type: 'invalid',
          message: 'You can only withdraw less than your current remaining streamable balance.',
        };
      }
    } else {
      validationState = { type: 'unvalidated' };
    }
  }

  function getAssetConfigHistory(dripsUserId: string, tokenAddress: string) {
    return (
      $streams.accounts[dripsUserId].assetConfigs.find((ac) => ac.tokenAddress === tokenAddress) ??
      unreachable()
    ).history;
  }

  async function withdraw(amountWei: bigint, updateAwaitStepFn: UpdateAwaitStepFn) {
    const { address, dripsUserId } = $wallet;
    assert(address && dripsUserId);

    const addressDriverClient = await getAddressDriverClient();

    const ownAccount = $streams.accounts[dripsUserId];
    assert(ownAccount, "App hasn't yet fetched user's own account");

    const assetConfig = ownAccount.assetConfigs.find(
      (ac) => ac.tokenAddress === $context.tokenAddress,
    );
    assert(assetConfig, "App hasn't yet fetched the right asset config");

    const currentReceivers = assetConfig.streams.map((stream) => ({
      userId: stream.receiver.userId,
      config: stream.dripsConfig.raw,
    }));

    updateAwaitStepFn({
      icon: {
        component: Emoji,
        props: {
          emoji: '👛',
          size: 'huge',
        },
      },
      message: 'Waiting for you to confirm the transaction in your wallet…',
    });

    const tx = await addressDriverClient.setDrips(
      $context.tokenAddress,
      currentReceivers,
      currentReceivers,
      address,
      -amountWei,
    );

    updateAwaitStepFn({
      message: 'Waiting for your transaction to be confirmed…',
      link: {
        url: etherscanLink($wallet.network.name, tx.hash),
        label: 'View on Etherscan',
      },
    });

    await tx.wait(1);

    updateAwaitStepFn({
      message: 'Wrapping up…',
    });

    const currentAssetConfigHistoryLength = getAssetConfigHistory(
      dripsUserId,
      $context.tokenAddress,
    ).length;

    await expect(
      streams.refreshUserAccount,
      () =>
        getAssetConfigHistory(dripsUserId, $context.tokenAddress).length >
        currentAssetConfigHistoryLength,
      5000,
      1000,
    );
  }

  function triggerWithdraw() {
    dispatch('await', {
      promise: (fn) => withdraw(amountWei ?? unreachable(), fn),
      message: 'Preparing to withdraw…',
    });
  }
</script>

<StepLayout>
  <EmojiAndToken emoji="🤑" tokenAddress={tokenInfo.info.address} animateTokenOnMount />
  <StepHeader
    headline={`Withdraw ${tokenInfo?.info.symbol}`}
    description="Withdraw funds from your outgoing streaming balance."
  />
  <FormField title="Balance">
    <div class="balance">
      <ListSelect
        blockInteraction
        searchable={false}
        items={{
          '': {
            type: 'selectable',
            label: tokenInfo.info.name ?? 'Unknown token',
            text: `${formatTokenAmount(estimate, tokenInfo.info.decimals)} ${
              tokenInfo.info.symbol
            }`,
            image: {
              component: Token,
              props: {
                address: $context.tokenAddress,
                show: 'none',
                size: 'small',
              },
            },
          },
        }}
      />
    </div>
  </FormField>
  <FormField title="Amount to withdraw">
    <TextInput
      bind:value={amount}
      variant={{ type: 'number', min: 0 }}
      suffix={tokenInfo.info.symbol}
      placeholder="Enter amount"
      {validationState}
    />
  </FormField>
  <svelte:fragment slot="actions">
    <Button disabled={validationState.type !== 'valid'} on:click={triggerWithdraw}>Withdraw</Button>
  </svelte:fragment>
</StepLayout>

<style>
  .balance {
    border: 2px solid var(--color-foreground-level-2);
    border-radius: 0.5rem;
  }
</style>