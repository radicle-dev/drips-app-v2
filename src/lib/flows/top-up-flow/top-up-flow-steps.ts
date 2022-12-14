import { makeStep } from '$lib/components/stepper/types';
import topUpFlowState, { type TopUpFlowState } from './top-up-flow-state';
import assert from '$lib/utils/assert';
import EnterAmountStep from './enter-amount.svelte';
import ApproveStep from './approve.svelte';
import TriggerTopUpTransactionStep from './trigger-top-up-transaction.svelte';
import FetchAllowanceAndBalanceStep from './fetch-allowance-and-balance.svelte';
import SelectTokenStep from './select-token.svelte';
import SuccessStep from '$lib/components/success-step/success-step.svelte';
import tokens from '$lib/stores/tokens';
import formatTokenAmount from '$lib/utils/format-token-amount';
import { get } from 'svelte/store';

function getSuccessMessage(state: TopUpFlowState) {
  const { tokenAddress, amountToTopUp } = state;
  assert(tokenAddress && amountToTopUp);

  const tokenInfo = tokens.getByAddress(tokenAddress);
  assert(tokenInfo);

  const formattedAmount = formatTokenAmount(
    { tokenAddress, amount: amountToTopUp },
    tokenInfo.info.decimals,
    1n,
  );

  return `
    You've successfully topped up ${formattedAmount} ${tokenInfo.info.name}.
    It may take some time for your balance to update on your dashboard.
  `;
}

export default function getTopUpFlowSteps(tokenAddress?: string) {
  topUpFlowState.set({
    tokenAddress,
  });

  return {
    context: topUpFlowState,
    steps: [
      tokenAddress
        ? makeStep({
            component: FetchAllowanceAndBalanceStep,
            props: undefined,
          })
        : makeStep({
            component: SelectTokenStep,
            props: undefined,
          }),
      makeStep({
        component: EnterAmountStep,
        props: undefined,
      }),
      makeStep({
        component: ApproveStep,
        props: undefined,
      }),
      makeStep({
        component: TriggerTopUpTransactionStep,
        props: undefined,
      }),
      makeStep({
        component: SuccessStep,
        props: {
          message: () => getSuccessMessage(get(topUpFlowState)),
        },
      }),
    ],
  };
}
