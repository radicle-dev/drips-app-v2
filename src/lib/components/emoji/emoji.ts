import CheckIcon from '$lib/components/icons/β.svelte';
import WarningIcon from '$lib/components/icons/β οΈ.svelte';
import GlobeIcon from '$lib/components/icons/π.svelte';
import PurseIcon from '$lib/components/icons/π.svelte';
import SkullIcon from '$lib/components/icons/π.svelte';
import MoneyBagIcon from '$lib/components/icons/π°.svelte';
import FlyingMoneyIcon from '$lib/components/icons/πΈ.svelte';
import LockIcon from '$lib/components/icons/π.svelte';
import WebIcon from '$lib/components/icons/πΈοΈ.svelte';
import MoneyEyesIcon from '$lib/components/icons/π€.svelte';
import MonocleIcon from '$lib/components/icons/π§.svelte';
import PourIcon from '$lib/components/icons/π«.svelte';
import JarIcon from '$lib/components/icons/π«.svelte';
import BubblesIcon from '$lib/components/icons/π«§.svelte';
import type { SvelteComponent } from 'svelte';

export const CUSTOM_EMOJI_COMPONENTS: { [key: string]: typeof SvelteComponent } = {
  ['β']: CheckIcon,
  ['β οΈ']: WarningIcon,
  ['π']: GlobeIcon,
  ['π']: PurseIcon,
  ['π']: SkullIcon,
  ['π°']: MoneyBagIcon,
  ['πΈ']: FlyingMoneyIcon,
  ['π']: LockIcon,
  ['πΈοΈ']: WebIcon,
  ['π€']: MoneyEyesIcon,
  ['π§']: MonocleIcon,
  ['π«']: PourIcon,
  ['π«']: JarIcon,
  ['π«§']: BubblesIcon,
};
