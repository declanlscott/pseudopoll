<script lang="ts" setup>
import { formatDistance, formatDuration, intervalToDuration } from "date-fns";

// eslint-disable-next-line import/order
import { voteRouterParamsSchema } from "~/schemas/polls";

import type { FormSubmitEvent } from "#ui/types";
import type { z } from "zod";

const config = useRuntimeConfig();

const { params } = useRoute();

const pollId = params.pollId as string;

const { getPoll } = usePollsStore();
const poll = ref(await getPoll(pollId));

const schema = voteRouterParamsSchema(config.public);
type Schema = z.infer<typeof schema>;

const state = ref<Partial<Schema>>({ pollId });

const isSubmitting = ref(false);
const error = ref<Error | null>(null);

async function onSubmit(event: FormSubmitEvent<Schema>) {
  isSubmitting.value = true;
  error.value = null;

  const { pollId, optionId } = event.data;

  try {
    if (poll.value?.options.some((option) => option.optionId === optionId)) {
      throw new Error("ALREADY_VOTED");
    }

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { requestId } = await $fetch(`/api/polls/${pollId}/${optionId}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
    });

    // TODO: Subscribe to the requestId channel and wait for the result.

    usePollsStore().vote(pollId, optionId);
    useRouter().push(`/${pollId}/results`);
  } catch (err: any) {
    if (err.message === "ALREADY_VOTED") {
      error.value = {
        name: "Invalid vote",
        message: "You have already voted on this poll.",
      };
    } else {
      error.value = {
        name: "Unknown error",
        message: "An unknown error occurred. Please try again later.",
      };
    }
  } finally {
    isSubmitting.value = false;
  }

  isSubmitting.value = false;
}

let intervalId: NodeJS.Timeout;
const timeLeft = ref(0);

onMounted(() => {
  calculateTimeLeft();
  intervalId = setInterval(calculateTimeLeft, 1000);
});

function calculateTimeLeft() {
  if (!poll.value) {
    timeLeft.value = 0;
    return;
  }

  const now = Date.now();
  const createdAt = new Date(poll.value.createdAt).getTime();
  const expiresAt = createdAt + poll.value.duration * 1000;

  timeLeft.value = Math.floor((expiresAt - now) / 1000);
}

onBeforeUnmount(() => {
  clearInterval(intervalId);
});
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
        ></URadio>
      </div>

      <div class="flex flex-row-reverse gap-2">
        <UButton
          color="primary"
          size="lg"
          icon="i-heroicons-document-check"
          type="submit"
          :loading="isSubmitting"
        >
          {{ isSubmitting ? "Voting..." : "Vote" }}
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
        v-if="error"
        :title="error.name"
        :description="error.message"
        color="red"
        variant="outline"
      ></UAlert>
    </UForm>
  </div>
</template>
