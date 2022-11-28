<script lang="ts">
  import highlightStore from '$lib/stores/highlight/highlight.store';
  import scroll from '$lib/stores/scroll';

  $: currentHighlight = $highlightStore;

  let boundingClientRect: DOMRect | undefined;
  $: {
    $scroll.pos;
    if (currentHighlight) boundingClientRect = currentHighlight.element.getBoundingClientRect();
  }

  let windowWidth: number;
  let windowHeight: number;
</script>

<svelte:window bind:innerHeight={windowHeight} bind:innerWidth={windowWidth} />

{#if boundingClientRect && windowWidth && windowHeight}
  <div class="highlight">
    <svg height={windowHeight} width={windowWidth}>
      <path
        fill="black"
        d={`M0 0 h${windowWidth} v${windowHeight} h-${windowWidth}z M${boundingClientRect.left} ${boundingClientRect.top} v${boundingClientRect.height} l${boundingClientRect.right} -20z`}
      />
    </svg>
  </div>
{/if}

<style>
  .highlight {
    z-index: 100;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
  }
</style>
