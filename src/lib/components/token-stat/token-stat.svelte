<script lang="ts">
  export let title: string;
</script>

<section
  class="token-stat border rounded-xl pt-3 px-4 pb-3"
  style="border-color:var(--color-foreground)"
>
  <header class="flex flex-wrap justify-between items-end">
    <h3 class="typo-text-bold">{title}</h3>
    <div>
      <slot name="detail" />
    </div>
  </header>

  <!-- amount -->
  <div class="mt-10 text-right text-typo-header-1 font-mono font-bold">
    <slot name="value" />
  </div>

  <!-- actions -->
  <footer class="flex justify-end mt-5 -mr-1">
    <slot name="actions" />
  </footer>
</section>
