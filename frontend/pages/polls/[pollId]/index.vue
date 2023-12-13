<script lang="ts" setup>
const { params } = useRoute();

const pollId = params.pollId as string;

const { data, error } = useFetch(`/api/polls/${pollId}`);

function vote(optionId: string) {
  $fetch(`/api/polls/${pollId}/${optionId}`, {
    method: "POST",
  });
}

function archive(archived: boolean) {
  $fetch(`/api/polls/${pollId}`, {
    method: "DELETE",
    body: JSON.stringify({ archived }),
  });
}

function closeNow() {
  $fetch(`/api/polls/${pollId}`, {
    method: "PATCH",
    body: JSON.stringify({ duration: -1 }),
  });
}
</script>

<template>
  <div>
    <h1>Vote</h1>

    <div v-if="error">{{ error.message }}</div>

    <div v-if="data">
      <h1>{{ data.prompt }}</h1>
      <ul>
        <li
          v-for="option in data.options"
          :key="option.optionId"
          @click="vote(option.optionId)"
        >
          {{ option.text }}
        </li>
      </ul>
    </div>

    <button @click="archive(true)">Archive</button>

    <button @click="closeNow">Close Now</button>
  </div>
</template>
