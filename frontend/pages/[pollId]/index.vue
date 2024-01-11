<script lang="ts" setup>
import { formatDistance, formatDuration, intervalToDuration } from "date-fns";

// eslint-disable-next-line import/order
import { voteRouterParamsSchema } from "~/schemas/polls";

import type { FormSubmitEvent } from "#ui/types";
import type { z } from "zod";

const { params } = useRoute();
const pollId = params.pollId as string;
const {
  query: { data, suspense },
  time,
} = usePoll({ pollId });
onServerPrefetch(async () => await suspense());
const poll = computed(() => data.value);

const {
  mutate: vote,
  isPending: voteIsPendingRef,
  error: voteErrorRef,
} = useVote({ pollId });
const voteIsPending = computed(() => voteIsPendingRef.value);
const voteError = computed(() => voteErrorRef.value);

const config = useRuntimeConfig();
const schema = voteRouterParamsSchema(config.public);
type Schema = z.infer<typeof schema>;

const state = ref<Partial<Schema>>({ pollId });

const router = useRouter();

function onSubmit(event: FormSubmitEvent<Schema>) {
  vote(
    { optionId: event.data.optionId },
    { onSuccess: () => router.push(`/${pollId}/results`) },
  );
}
</script>

<template>
  <div class="flex justify-center">
    <UForm
      v-if="poll"
      :state="state"
      :schema="schema"
      class="flex w-2/3 flex-col gap-6"
      @submit="onSubmit"
    >
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
                new Date(poll.createdAt).getTime() + time.duration * 1000,
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

      <h1 class="text-3xl font-bold">{{ poll.prompt }}</h1>

      <div class="flex flex-col">
        <URadio
          v-for="option of poll.options"
          :key="option.optionId"
          v-model="state.optionId"
          :value="option.optionId"
          :label="option.text"
          :ui="{
            base: 'h-5 w-5',
            container: 'mt-4',
            inner: 'grow ms-0',
            label: cn(
              'text-xl text-gray-500 dark:text-gray-400 py-3 ps-4',
              state.optionId === option.optionId &&
                'text-black dark:text-white',
            ),
          }"
          :disabled="time.left <= 0"
        ></URadio>
      </div>

      <div class="flex flex-row-reverse gap-2">
        <UButton
          v-if="time.left > 0"
          color="primary"
          size="lg"
          icon="i-heroicons-document-check"
          type="submit"
          :loading="voteIsPending"
        >
          {{ voteIsPending ? "Voting..." : "Vote" }}
        </UButton>

        <UButton
          color="gray"
          size="lg"
          icon="i-heroicons-chart-bar"
          :to="`/${pollId}/results`"
          :ui="{
            icon: {
              base: 'rotate-90',
            },
          }"
        >
          Results
        </UButton>
      </div>

      <UAlert
        v-if="voteError"
        title="Vote Error"
        :description="voteError.message"
        color="red"
        variant="outline"
      ></UAlert>
    </UForm>
  </div>
</template>
