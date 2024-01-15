<script lang="ts" setup>
import type { Feature } from "~/types";

const props = defineProps<Feature>();
const { title } = toRefs(props);
</script>

<template>
  <UCard>
    <template #header>{{ title }}</template>
  </UCard>
</template>
