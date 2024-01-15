<script lang="ts" setup>
const features: { title: string }[] = [
  {
    title: "test",
  },
];
</script>

<template>
  <FeatureCard
    v-for="{ title } in features"
    :key="title"
    :title="title"
  ></FeatureCard>
</template>
