<script lang="ts" setup>
import type { Feature } from "~/types";

const props = defineProps<Feature>();
const { title, description, icon } = toRefs(props);
</script>

<template>
  <UCard>
    <template #header>
      <div
        class="dark:text-primary-50 text-primary-950 flex items-center gap-3"
      >
        <UIcon :name="icon" class="h-7 w-7"></UIcon>

        <h3 class="text-2xl font-semibold">
          {{ title }}
        </h3>
      </div>
    </template>

    <p class="dark:text-primary-50/75 text-primary-950/75">{{ description }}</p>
  </UCard>
</template>
