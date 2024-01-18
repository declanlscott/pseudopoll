<script setup lang="ts">
import { VueQueryDevtools } from "@tanstack/vue-query-devtools";

useHead({
  titleTemplate: (titleChunk) =>
    titleChunk
      ? `${titleChunk} | PseudoPoll`
      : "PseudoPoll | The Internet's Polling Place",
});
</script>

<template>
  <NuxtLayout>
    <NuxtPage />
    <VueQueryDevtools />
  </NuxtLayout>
</template>
