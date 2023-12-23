import { defineStore } from "pinia";

import type { paths } from "~/openapi/types/generated";

type Poll =
  paths["/polls/{pollId}"]["get"]["responses"]["200"]["content"]["application/json"];

export const usePollsStore = defineStore("polls", () => {
  const polls = ref<Map<Poll["pollId"], Poll>>(new Map());

  const addPoll = (poll: Poll) => polls.value.set(poll.pollId, poll);

  const getPoll = async (pollId: Poll["pollId"]) => {
    let poll = polls.value.get(pollId);

    if (!poll) {
      poll = await $fetch(`/api/polls/${pollId}`, { method: "GET" });

      if (poll) {
        addPoll(poll);
      }
    }

    return poll;
  };

  return { polls, addPoll, getPoll };
});
