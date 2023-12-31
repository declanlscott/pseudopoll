<script lang="ts" setup>
import type { paths } from "~/openapi/types/generated";

const { option, totalVotes } = defineProps<{
  option: paths["/polls/{pollId}"]["get"]["responses"]["200"]["content"]["application/json"]["options"][number];
  totalVotes: number;
}>();

const percentage = computed(() => {
  if (totalVotes === 0) {
    return "0%";
  }

  return `${Math.floor((option.votes / totalVotes) * 100)}%`;
});
</script>

<template>
  <div
    class="relative flex justify-between gap-3 rounded-xl border border-gray-200 px-4 py-3 dark:border-gray-700"
  >
    <p class="text-xl">{{ option.text }}</p>

    <span
      :class="
        cn(
          'mt-1 h-fit text-sm text-gray-500 dark:text-gray-400',
          option.isMyVote && 'text-black dark:text-white',
        )
      "
    >
      {{ percentage }}
    </span>

    <div
      :class="
        cn(
          'percentage-bar absolute left-0 top-0 -z-10 h-full rounded-lg transition duration-300 ease-in-out',
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
