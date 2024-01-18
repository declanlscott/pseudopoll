<script lang="ts" setup>
import type { Feature } from "~/types";

const features: Feature[] = [
  {
    title: "Customizable Polls",
    description:
      "Create polls with up to 10 options with durations as short as a minute or as long as a week.",
    icon: "i-lucide-settings",
  },
  {
    title: "Shareable Links",
    description:
      "Share your polls with your friends, family, or followers with a simple link.",
    icon: "i-lucide-link",
  },
  {
    title: "Real-Time Results",
    description: "Watch the results of your polls update in real-time.",
    icon: "i-lucide-bar-chart-horizontal-big",
  },
  {
    title: "Anonymous Voting",
    description:
      "Vote on polls without having to login, while also preventing users from voting multiple times.",
    icon: "i-lucide-user-check",
  },
];
</script>

<template>
  <section class="flex flex-col items-center justify-center gap-9">
    <div class="flex flex-col gap-3">
      <h2
        class="dark:text-primary-50 text-primary-950 text-center text-4xl font-bold"
      >
        What's in PseudoPoll?
      </h2>
      <span class="dark:text-primary-50/75 text-primary-950/75 text-center">
        Everything you need, and nothing you don't.
      </span>
    </div>

    <div class="grid w-full grid-cols-1 gap-6 sm:grid-cols-2">
      <FeatureCard
        v-for="{ title, description, icon } in features"
        :key="title"
        :title="title"
        :description="description"
        :icon="icon"
      ></FeatureCard>
    </div>
  </section>
</template>
