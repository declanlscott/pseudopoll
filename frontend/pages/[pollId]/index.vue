<script lang="ts" setup>
import { formatDistance, formatDuration, intervalToDuration } from "date-fns";

// eslint-disable-next-line import/order
import { voteRouterParamsSchema } from "~/schemas/polls";

import type { FormSubmitEvent } from "#ui/types";
import type { z } from "zod";

const { params } = useRoute();
const pollId = params.pollId as string;
const { query, time } = usePoll({ pollId });
onServerPrefetch(async () => await query.suspense());

const { mutation: vote } = useVote({ pollId });

const config = useRuntimeConfig();
const schema = voteRouterParamsSchema(config.public);
type Schema = z.infer<typeof schema>;

const state = ref<Partial<Schema>>({ pollId });

const { push } = useRouter();

function onSubmit(event: FormSubmitEvent<Schema>) {
  vote.mutate(
    { optionId: event.data.optionId },
    { onSuccess: () => push(`/${pollId}/results`) },
  );
}
</script>

<template>
  <div>
    <div v-show="query.isLoading.value" class="flex justify-center">
      <UIcon
        name="i-heroicons-arrow-path-20-solid"
        class="text-primary-500 dark:text-primary-400 h-16 w-16 animate-spin"
      ></UIcon>
    </div>

    <UForm
      v-if="query.data.value"
      :state="state"
      :schema="schema"
      class="flex flex-col gap-6"
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

      <h1 class="text-3xl font-bold">{{ query.data.value.prompt }}</h1>

      <div class="flex flex-col">
        <URadio
          v-for="option of query.data.value.options"
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
          icon="i-lucide-vote"
          type="submit"
          :loading="vote.isPending.value"
        >
          {{ vote.isPending.value ? "Voting..." : "Vote" }}
        </UButton>

        <UButton
          color="gray"
          size="lg"
          icon="i-lucide-bar-chart-horizontal-big"
          :to="`/${pollId}/results`"
        >
          Results
        </UButton>
      </div>

      <UAlert
        v-if="vote.error.value"
        title="Vote Error"
        :description="vote.error.value.message"
        color="red"
        variant="outline"
      ></UAlert>
    </UForm>
  </div>
</template>
