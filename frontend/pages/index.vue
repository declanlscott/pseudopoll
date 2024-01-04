<script setup lang="ts">
// eslint-disable-next-line import/order
import { createPollBodySchema } from "~/schemas/polls";

import type { FormSubmitEvent } from "#ui/types";
import type { z } from "zod";

const config = useRuntimeConfig();
const { status } = useAuth();

const schema = createPollBodySchema(config.public);
type Schema = z.infer<typeof schema>;

const state = ref<Schema>({
  prompt: "",
  options: Array.from({ length: config.public.minOptions }, () => ""),
  duration: config.public.minDuration,
});

const { durations, create, isSubmitting, error } = useCreate();

async function onSubmit(event: FormSubmitEvent<Schema>) {
  await create({ poll: event.data });
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
        title="Error"
        :description="error.message"
        color="red"
        variant="outline"
      ></UAlert>
    </UForm>
  </div>
</template>
