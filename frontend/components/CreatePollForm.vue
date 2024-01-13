<script setup lang="ts">
// eslint-disable-next-line import/order
import { createPollBodySchema } from "~/schemas/polls";

import type { FormSubmitEvent } from "#ui/types";
import type { z } from "zod";

const config = useRuntimeConfig();

const schema = createPollBodySchema(config.public);
type Schema = z.infer<typeof schema>;

const state = ref<Schema>({
  prompt: "",
  options: Array.from({ length: config.public.minOptions }, () => ""),
  duration: config.public.minDuration,
});

const { mutation, durations } = useCreate();

const { push } = useRouter();

function onSubmit(event: FormSubmitEvent<Schema>) {
  mutation.mutate(
    { poll: event.data },
    { onSuccess: ({ pollId }) => push(`/${pollId}`) },
  );
}

const placeholder =
  placeholders.poll[Math.floor(Math.random() * placeholders.poll.length)];
</script>

<template>
  <UForm
    :schema="schema"
    :state="state"
    class="flex w-full flex-col gap-6"
    @submit="onSubmit"
  >
    <h1 class="text-3xl font-bold">Create a poll</h1>

    <UFormGroup name="prompt" label="Prompt">
      <ClientOnly>
        <template #fallback>
          <UTextarea size="xl" class="w-full" disabled></UTextarea>
        </template>

        <UTextarea
          v-model="state.prompt"
          :placeholder="placeholder.prompt"
          size="xl"
          class="w-full"
          :disabled="mutation.isPending.value"
        ></UTextarea>
      </ClientOnly>
    </UFormGroup>

    <ul class="flex flex-col gap-3">
      <li v-for="(_, index) in state.options" :key="index">
        <UFormGroup
          :name="`options.${index}`"
          :label="`Option ${index + 1}`"
          class="w-full"
        >
          <ClientOnly>
            <template #fallback>
              <UInput size="lg" class="w-full" disabled></UInput>
            </template>

            <UInput
              v-model="state.options[index]"
              size="lg"
              :placeholder="`${
                index === 0
                  ? placeholder.options[index]
                  : index === 1
                    ? placeholder.options[index]
                    : ''
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
              :disabled="mutation.isPending.value"
            >
              <div class="absolute inset-y-0 end-0 flex items-center">
                <UTooltip
                  v-show="
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
                    :disabled="mutation.isPending.value"
                    @click="state.options.push('')"
                  ></UButton>
                </UTooltip>

                <UTooltip
                  v-show="index > $config.public.minOptions - 1"
                  :text="`Remove option ${index + 1}`"
                >
                  <UButton
                    color="gray"
                    icon="i-heroicons-minus"
                    size="lg"
                    class="rounded-l-none"
                    :disabled="mutation.isPending.value"
                    @click="state.options.splice(index, 1)"
                  ></UButton>
                </UTooltip>
              </div>
            </UInput>
          </ClientOnly>
        </UFormGroup>
      </li>
    </ul>

    <div class="flex items-end justify-between">
      <UFormGroup name="duration" label="Duration">
        <USelect
          v-model="state.duration"
          name="duration"
          :options="durations"
          :disabled="mutation.isPending.value"
          class="w-fit"
        ></USelect>
      </UFormGroup>

      <UButton
        color="primary"
        size="lg"
        icon="i-heroicons-pencil-square"
        :loading="mutation.isPending.value"
        type="submit"
      >
        {{ mutation.isPending.value ? "Creating..." : "Create" }}
      </UButton>
    </div>

    <UAlert
      v-if="mutation.error.value"
      title="Error"
      :description="mutation.error.value.message"
      color="red"
      variant="outline"
    ></UAlert>
  </UForm>
</template>
