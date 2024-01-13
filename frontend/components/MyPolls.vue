<script lang="ts" setup>
import { format } from "date-fns";

import type { Poll } from "~/types";

const { query } = useMyPolls();
onServerPrefetch(async () => await query.suspense());

const queryClient = useQueryClient();
const { poll } = useQueryOptionsFactory();

async function prefetchPoll({ pollId }: { pollId: Poll["pollId"] }) {
  await queryClient.prefetchQuery(poll({ pollId }));
}

function formatDate(date: string) {
  return format(new Date(date), "MMMM do, yyyy");
}
</script>

<template>
  <div>
    <h2 class="mb-6 text-2xl font-bold">My polls</h2>

    <ul v-show="query.isLoading.value" class="grid grid-cols-1 gap-3">
      <li v-for="i in 3" :key="i">
        <UCard
          :ui="{
            base: 'group relative hover:dark:bg-gray-800 duration-75 transition-colors hover:bg-gray-100 cursor-pointer',
            body: { padding: 'p-4 sm:p-4' },
          }"
        >
          <div class="flex flex-col gap-1">
            <div
              class="h-4 w-3/4 animate-pulse rounded bg-gray-300 dark:bg-gray-700"
            ></div>
            <div
              class="h-4 w-1/2 animate-pulse rounded bg-gray-300 dark:bg-gray-700"
            ></div>
          </div>
        </UCard>
      </li>
    </ul>

    <ul v-if="query.data.value" class="grid grid-cols-1 gap-3">
      <li
        v-for="{ pollId, prompt, createdAt, isArchived } in query.data.value"
        :key="pollId"
      >
        <UCard
          :ui="{
            base: 'group relative hover:dark:bg-gray-800 duration-75 transition-colors hover:bg-gray-100',
            body: { padding: 'p-4 sm:p-4' },
          }"
        >
          <div class="flex items-center justify-between gap-3">
            <div class="flex flex-col gap-1">
              <NuxtLink
                :to="`/${pollId}/results`"
                class="text-xl after:absolute after:inset-0 group-hover:underline"
                @mouseenter="prefetchPoll({ pollId })"
              >
                {{ prompt }}
              </NuxtLink>

              <span class="text-sm text-gray-500">
                Created on {{ formatDate(createdAt) }}
              </span>
            </div>

            <UIcon
              v-show="isArchived"
              name="i-heroicons-archive-box"
              class="h-5 w-5 text-gray-500"
            ></UIcon>
          </div>
        </UCard>
      </li>
    </ul>
  </div>
</template>
