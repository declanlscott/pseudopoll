<script setup lang="ts">
// eslint-disable-next-line import/order
import { createPollBodySchema } from "~/schemas/polls";

import type { FormSubmitEvent } from "#ui/types";
import type { z } from "zod";

const config = useRuntimeConfig();
const { status, signIn } = useAuth();

const schema = createPollBodySchema(config.public);
type Schema = z.infer<typeof schema>;

const state = ref<Schema>({
  prompt: "",
  options: Array.from({ length: config.public.minOptions }, () => ""),
  duration: config.public.minDuration,
});

const isSubmitting = ref(false);
const error = ref<Error | null>(null);

const durations = [
  { label: "1 minute", value: 60 },
  { label: "5 minutes", value: 300 },
  { label: "15 minutes", value: 900 },
  { label: "30 minutes", value: 1800 },
  { label: "1 hour", value: 3600 },
  { label: "2 hours", value: 7200 },
  { label: "6 hours", value: 21600 },
  { label: "12 hours", value: 43200 },
  { label: "1 day", value: 86400 },
  { label: "2 days", value: 172800 },
  { label: "3 days", value: 259200 },
  { label: "1 week", value: 604800 },
];

async function onSubmit(event: FormSubmitEvent<Schema>) {
  isSubmitting.value = true;
  error.value = null;

  try {
    const poll = await $fetch("/api/polls", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(event.data),
    });

    usePollsStore().addPoll(poll);
    useRouter().push(`/${poll.pollId}`);
  } catch (err: any) {
    if (err.message.includes("401")) {
      error.value = {
        name: "Session expired",
        message: "Your session has expired. Please sign in again.",
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
}
</script>

<template>
  <div v-if="status === 'authenticated'" class="flex justify-center">
    <UForm
      :schema="schema"
      :state="state"
      class="flex w-2/3 flex-col gap-6"
      @submit="onSubmit"
    >
      <h1 class="text-3xl font-bold">Create a poll</h1>

      <UFormGroup name="prompt" label="Prompt">
        <UTextarea
          v-model="state.prompt"
          placeholder="Pancakes or waffles?"
          size="xl"
          class="w-full"
          :disabled="isSubmitting"
        ></UTextarea>
      </UFormGroup>

      <ul class="flex flex-col gap-3">
        <li v-for="(_, index) in state.options" :key="index">
          <UFormGroup
            :name="`options.${index}`"
            :label="`Option ${index + 1}`"
            class="w-full"
          >
            <UInput
              v-model="state.options[index]"
              size="lg"
              :placeholder="`${
                index === 0 ? 'Pancakes!' : index === 1 ? 'Waffles!' : ''
              }`"
              :input-class="
                cn(
                  // minimum and last option
                  index === state.options.length - 1 && 'pr-[54px]',

                  // minimum + 1 to maximum - 1 option, but not last
                  index > $config.public.minOptions - 1 && 'pr-[54px]',

                  // last option, but not maximum
                  index === state.options.length - 1 &&
                    index > config.public.minOptions - 1 &&
                    'pr-[94px]',

                  // maximum option
                  index === $config.public.maxOptions - 1 && 'pr-[54px]',
                )
              "
              :disabled="isSubmitting"
            >
              <div class="absolute inset-y-0 end-0 flex items-center">
                <UTooltip
                  v-if="
                    index === state.options.length - 1 &&
                    index < $config.public.maxOptions - 1
                  "
                  :text="`Add option ${index + 2}`"
                >
                  <UButton
                    icon="i-heroicons-plus"
                    size="lg"
                    :class="
                      cn(
                        'rounded-l-none',
                        index > $config.public.minOptions - 1 &&
                          'rounded-r-none',
                      )
                    "
                    :disabled="isSubmitting"
                    @click="state.options.push('')"
                  ></UButton>
                </UTooltip>

                <UTooltip
                  v-if="index > $config.public.minOptions - 1"
                  :text="`Remove option ${index + 1}`"
                >
                  <UButton
                    color="gray"
                    icon="i-heroicons-minus"
                    size="lg"
                    class="rounded-l-none"
                    :disabled="isSubmitting"
                    @click="state.options.splice(index, 1)"
                  ></UButton>
                </UTooltip>
              </div>
            </UInput>
          </UFormGroup>
        </li>
      </ul>

      <div class="flex items-end justify-between">
        <UFormGroup name="duration" label="Duration">
          <USelect
            v-model="state.duration"
            name="duration"
            :options="durations"
            :disabled="isSubmitting"
            class="w-fit"
          ></USelect>
        </UFormGroup>

        <UButton
          color="primary"
          size="lg"
          icon="i-heroicons-pencil-square"
          :loading="isSubmitting"
          type="submit"
        >
          {{ isSubmitting ? "Creating..." : "Create" }}
        </UButton>
      </div>

      <UAlert
        v-if="error"
        :title="error.name"
        :description="error.message"
        color="red"
        variant="outline"
        :actions="
          error.name === 'Session expired'
            ? [
                {
                  variant: 'solid',
                  color: 'gray',
                  label: 'Sign in',
                  icon: 'i-heroicons-arrow-right',
                  trailing: true,
                  click: signIn,
                },
              ]
            : []
        "
      ></UAlert>
    </UForm>
  </div>
</template>
