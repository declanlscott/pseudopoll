<script lang="ts" setup>
import type { Poll } from "~/types";

const props = defineProps<{
  option: Poll["options"][number];
  totalVotes: number;
}>();
const { option, totalVotes } = toRefs(props);

const percentage = computed(() => {
  if (totalVotes.value === 0) {
    return "0%";
  }

  return `${Math.floor((option.value.votes / totalVotes.value) * 100)}%`;
});
</script>

<template>
  <div
    class="relative flex justify-between gap-3 rounded-xl border border-gray-200 px-4 py-3 dark:border-gray-700"
  >
    <p :class="cn('text-xl', option.isMyVote && 'font-bold')">
      {{ option.text }}
    </p>

    <span
      :class="
        cn(
          'mt-1 h-fit text-sm text-gray-500 dark:text-gray-400',
          option.isMyVote && 'font-bold text-black dark:text-white',
        )
      "
    >
      {{ percentage }}
    </span>

    <div
      :class="
        cn(
          'percentage-bar absolute left-0 top-0 -z-10 h-full rounded-lg transition-all duration-300 ease-in-out',
          option.isMyVote
            ? 'bg-primary-400/25'
            : 'bg-gray-100 dark:bg-gray-800',
        )
      "
    ></div>
  </div>
</template>

<style scoped>
.percentage-bar {
  width: v-bind(percentage);
}
</style>
