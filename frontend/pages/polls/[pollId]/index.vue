<script lang="ts" setup>
const { params } = useRoute();

const pollId = params.pollId as string;

const { getPoll } = usePollsStore();
const poll = await getPoll(pollId);

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

    <!-- <div v-if="error">{{ error.message }}</div> -->

    <div v-if="poll">
      <h1>{{ poll.prompt }}</h1>
      <ul>
        <li
          v-for="option in poll.options"
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
