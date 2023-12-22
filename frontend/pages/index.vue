<script setup lang="ts">
import { z } from "zod";

import { createPollBodySchema } from "~/schemas/polls";

// eslint-disable-next-line import/order
import type { FormSubmitEvent } from "#ui/types";

const config = useRuntimeConfig();
const { status } = useAuth();

const schema = createPollBodySchema(config.public);
type Schema = z.infer<typeof schema>;

const state = ref<Schema>({
  prompt: "",
  options: Array.from({ length: config.public.minOptions }, () => ""),
  duration: config.public.minDuration,
});

function onSubmit(event: FormSubmitEvent<Schema>) {
  console.log("event", event);
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
                    :class="cn('rounded-l-none', index > 1 && 'rounded-r-none')"
                    @click="state.options.push('')"
                  ></UButton>
                </UTooltip>

                <UTooltip v-if="index > 1" :text="`Remove option ${index + 1}`">
                  <UButton
                    color="gray"
                    icon="i-heroicons-minus"
                    size="lg"
                    class="rounded-l-none"
                    @click="state.options.splice(index, 1)"
                  ></UButton>
                </UTooltip>
              </div>
            </UInput>
          </UFormGroup>
        </li>
      </ul>

      <UFormGroup name="duration" label="Duration">
        <URange
          id="duration"
          v-model="state.duration"
          :min="$config.public.minDuration"
          :max="$config.public.maxDuration"
          name="duration"
        ></URange>
      </UFormGroup>

      <div class="flex justify-end">
        <UButton
          color="primary"
          size="lg"
          icon="i-heroicons-pencil-square"
          type="submit"
        >
          Create
        </UButton>
      </div>
    </UForm>
  </div>
</template>
