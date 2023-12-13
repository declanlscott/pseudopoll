<script lang="ts" setup>
const { params } = useRoute();

const pollId = params.pollId as string;

const { data, error } = useFetch(`/api/polls/${pollId}`);

const calculatePercentage = (votes: number) => {
  const totalVotes = data.value?.options.reduce((acc, option) => {
    return acc + option.votes;
  }, 0);

  if (!totalVotes) {
    return 0;
  }

  return Math.round((votes / totalVotes) * 100);
};
</script>

<template>
  <UContainer>
    <h1 class="text-2xl">Results</h1>

    <div v-if="error">{{ error.message }}</div>

    <div v-if="data">
      <h2 class="text-3xl">{{ data.prompt }}</h2>

      <ul class="flex flex-col gap-4">
        <li
          v-for="option in data.options"
          :key="option.optionId"
          class="flex flex-col gap-2 rounded-lg bg-white px-4 py-2 shadow ring-1 ring-gray-200 dark:bg-gray-900 dark:ring-gray-800"
        >
          <div class="flex justify-between gap-4">
            <p>{{ option.text }}</p>

            <span class="self-end whitespace-nowrap text-sm text-gray-500">
              {{ calculatePercentage(option.votes) }}%
            </span>
          </div>

          <UMeter :value="calculatePercentage(option.votes)" />
        </li>
      </ul>
    </div>
  </UContainer>
</template>
