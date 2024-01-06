<script lang="ts" setup>
import { formatDistance, formatDuration, intervalToDuration } from "date-fns";

const { session } = useAuth();

const { params } = useRoute();
const pollId = params.pollId as string;
const {
  query: { data: poll, suspense },
  timeLeft,
  totalVotes,
  lastActivity,
} = usePoll({ pollId });
await suspense();

const {
  mutate: archive,
  isPending: isArchivePending,
  error: archiveError,
} = useArchive({ pollId });

const {
  mutate: updateDuration,
  isPending: durationIsPending,
  error: durationError,
} = useDuration({ pollId });
</script>

<template>
  <div class="flex justify-center">
    <div v-if="poll" class="flex w-2/3 flex-col gap-6">
      <UMeter :value="timeLeft" :max="poll.duration">
        <template #indicator>
          <span
            v-if="timeLeft > 0"
            class="text-right text-sm text-gray-500 dark:text-gray-400"
          >
            {{
              formatDuration(
                intervalToDuration({ start: 0, end: timeLeft * 1000 }),
              )
            }}
            left
          </span>

          <span
            v-else-if="timeLeft < 0"
            class="text-right text-sm text-gray-500 dark:text-gray-400"
          >
            Ended
            {{
              formatDistance(
                new Date(poll.createdAt).getTime() + poll.duration * 1000,
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
        <h1 class="text-3xl font-bold">{{ poll.prompt }}</h1>

        <div
          v-if="session && session.user.id === poll.userId"
          class="flex gap-2"
        >
          <UTooltip v-if="timeLeft > 0" text="Close now">
            <UButton
              icon="i-heroicons-clock"
              color="gray"
              :loading="durationIsPending"
              @click="() => updateDuration({ duration: -1 })"
            ></UButton>
          </UTooltip>

          <UTooltip :text="poll.isArchived ? 'Unarchive' : 'Archive'">
            <UButton
              :icon="
                poll.isArchived
                  ? 'i-heroicons-arrow-up-circle'
                  : 'i-heroicons-archive-box'
              "
              color="gray"
              :loading="isArchivePending"
              @click="() => archive({ isArchived: !poll?.isArchived })"
            ></UButton>
          </UTooltip>
        </div>
      </div>

      <ul class="flex flex-col gap-3">
        <li v-for="option in poll.options" :key="option.optionId">
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
            {{ lastActivity }}
          </span>
        </div>

        <UButton
          v-if="timeLeft > 0"
          color="gray"
          size="lg"
          icon="i-heroicons-document-check"
          type="button"
          :to="`/${pollId}`"
        >
          Vote
        </UButton>
      </div>

      <UAlert
        v-if="archiveError"
        title="Archive Error"
        :description="archiveError.message"
        color="red"
        variant="outline"
      ></UAlert>

      <UAlert
        v-if="durationError"
        title="Duration Error"
        :description="durationError.message"
        color="red"
        variant="outline"
      ></UAlert>
    </div>
  </div>
</template>
