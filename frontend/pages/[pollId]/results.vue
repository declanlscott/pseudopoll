<script lang="ts" setup>
import { formatDistance, formatDuration, intervalToDuration } from "date-fns";

const { session } = useAuth();

const { params } = useRoute();
const pollId = params.pollId as string;
const { query, time, totalVotes } = usePoll({ pollId });
onServerPrefetch(async () => await query.suspense());

useHead({
  title: `Results | ${query.data.value?.prompt ?? "Loading..."}`,
});

const { mutation: archive } = useArchive({ pollId });
const { mutation: duration } = useDuration({ pollId });
</script>

<template>
  <div>
    <div v-show="query.isLoading.value" class="flex justify-center">
      <UIcon
        name="i-heroicons-arrow-path-20-solid"
        class="text-primary-500 dark:text-primary-400 h-16 w-16 animate-spin"
      ></UIcon>
    </div>

    <div v-if="query.data.value" class="flex flex-col gap-6">
      <UMeter :value="time.left" :max="time.duration">
        <template #indicator>
          <span
            v-if="time.left > 0"
            class="text-right text-sm text-gray-500 dark:text-gray-400"
          >
            {{
              formatDuration(
                intervalToDuration({ start: 0, end: time.left * 1000 }),
              )
            }}
            left
          </span>

          <span
            v-else-if="time.left < 0"
            class="text-right text-sm text-gray-500 dark:text-gray-400"
          >
            Ended
            {{
              formatDistance(
                new Date(query.data.value.createdAt).getTime() +
                  time.duration * 1000,
                new Date(),
                { addSuffix: true },
              )
            }}
          </span>

          <span
            v-else
            class="text-right text-sm text-gray-500 dark:text-gray-400"
          >
            Calculating...
          </span>
        </template>
      </UMeter>

      <div class="flex justify-between gap-6">
        <h1 class="text-3xl font-bold">{{ query.data.value.prompt }}</h1>

        <div
          v-if="session && session.user.id === query.data.value.userId"
          class="flex h-fit gap-2"
        >
          <UTooltip v-if="time.left > 0" text="Close now">
            <UButton
              icon="i-lucide-timer-off"
              color="gray"
              :loading="duration.isPending.value"
              @click="duration.mutate({ duration: -1 })"
            ></UButton>
          </UTooltip>

          <UTooltip :text="query.data.value.isArchived ? 'Restore' : 'Archive'">
            <UButton
              :icon="
                query.data.value.isArchived
                  ? 'i-lucide-archive-restore'
                  : 'i-lucide-archive'
              "
              color="gray"
              :loading="archive.isPending.value"
              @click="
                archive.mutate({ isArchived: !query.data.value?.isArchived })
              "
            ></UButton>
          </UTooltip>
        </div>
      </div>

      <ul class="grid grid-cols-1 gap-3">
        <li v-for="option in query.data.value.options" :key="option.optionId">
          <OptionResult :option="option" :total-votes="totalVotes" />
        </li>
      </ul>

      <div class="flex items-start justify-between gap-3">
        <div class="flex gap-1 text-sm text-gray-500 dark:text-gray-400">
          <span>
            {{ `${totalVotes} vote${totalVotes === 1 ? "" : "s"}` }}
          </span>

          <span>•</span>

          <span>
            {{ time.lastActivity }}
          </span>
        </div>

        <UButton
          v-if="time.left > 0"
          color="gray"
          size="lg"
          icon="i-lucide-vote"
          type="button"
          :to="`/${pollId}`"
        >
          Vote
        </UButton>
      </div>

      <UAlert
        v-if="archive.error.value"
        title="Archive Error"
        :description="archive.error.value.message"
        color="red"
        variant="outline"
      ></UAlert>

      <UAlert
        v-if="duration.error.value"
        title="Duration Error"
        :description="duration.error.value.message"
        color="red"
        variant="outline"
      ></UAlert>
    </div>
  </div>
</template>
