<script setup lang="ts">
const { status } = useAuth();
</script>

<template>
  <div class="flex flex-col gap-12">
    <CreatePollForm v-if="status === 'authenticated'"></CreatePollForm>

    <MyPolls v-if="status === 'authenticated'"></MyPolls>
  </div>
</template>
