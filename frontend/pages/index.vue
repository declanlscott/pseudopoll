<script setup lang="ts">
const runtimeConfig = useRuntimeConfig();
const { status } = useAuth();

const prompt = ref("");
const options = ref(Array.from({ length: 2 }, () => ""));
const duration = ref(runtimeConfig.public.minDuration);
</script>

<template>
  <div v-if="status === 'authenticated'" class="flex justify-center">
    <div class="flex w-2/3 flex-col gap-6">
      <h1 class="text-3xl font-bold">Create a poll</h1>

      <UTextarea
        v-model="prompt"
        placeholder="Prompt..."
        size="xl"
        class="w-full"
      ></UTextarea>

      <ul class="flex flex-col gap-3">
        <li v-for="(option, index) in options" :key="index" class="flex gap-3">
          <UInput
            :placeholder="`Option ${index + 1}...`"
            size="lg"
            class="w-full"
          ></UInput>

          <UTooltip
            v-if="
              index === options.length - 1 &&
              index < $config.public.maxOptions - 1
            "
            :text="`Add option ${index + 2}`"
          >
            <UButton
              icon="i-heroicons-plus"
              class="w-fit self-center"
              @click="options.push('')"
            ></UButton>
          </UTooltip>

          <UTooltip v-if="index > 1" :text="`Remove option ${index + 1}`">
            <UButton
              color="gray"
              icon="i-heroicons-minus"
              class="w-fit self-center"
              @click="options.splice(index, 1)"
            ></UButton>
          </UTooltip>
        </li>
      </ul>

      <div class="flex flex-col gap-1.5">
        <div class="flex items-end justify-between">
          <label class="text-lg font-bold" for="duration">Duration</label>
          <span>{{ duration }}</span>
        </div>

        <URange
          id="duration"
          v-model="duration"
          :min="$config.public.minDuration"
          :max="$config.public.maxDuration"
          name="duration"
        ></URange>
      </div>

      <div class="flex justify-end">
        <UButton color="primary" size="lg" icon="i-heroicons-pencil-square">
          Create
        </UButton>
      </div>
    </div>
  </div>
</template>
