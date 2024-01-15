<script setup lang="ts">
const { status } = useAuth();
</script>

<template>
  <div v-if="status === 'authenticated'" class="flex flex-col gap-12">
    <CreatePollForm></CreatePollForm>

    <MyPolls></MyPolls>
  </div>

  <LandingPage v-else></LandingPage>
</template>
