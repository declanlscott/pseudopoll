<script lang="ts" setup>
async function submitPoll() {
  await $fetch("http://localhost:3000/api/polls", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      prompt: "What is your favorite color?",
      options: ["Red", "Blue", "Green"],
      duration: 600,
    }),
  });
}
</script>

<template>
  <div>
    <h1>Create a new poll</h1>
    <button @click="submitPoll">Submit</button>
  </div>
</template>

<style></style>
