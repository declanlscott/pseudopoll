<script setup lang="ts">
import { VueQueryDevtools } from "@tanstack/vue-query-devtools";
</script>

<template>
  <NuxtLayout>
    <NuxtPage />
    <VueQueryDevtools />
  </NuxtLayout>
</template>
