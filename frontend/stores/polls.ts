import { produce } from "immer";
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
      poll = await $fetch(`/api/polls/${pollId}`, {
        method: "GET",
        headers: useRequestHeaders(),
      });

      if (poll) {
        addPoll(poll);
      }
    }

    return poll;
  };

  const vote = (
    pollId: Poll["options"][number]["pollId"],
    optionId: Poll["options"][number]["optionId"],
  ) =>
    polls.value.set(
      pollId,
      produce(polls.value.get(pollId)!, (draft) => {
        const option = draft.options.find(
          (option) => option.optionId === optionId,
        );

        if (option) {
          option.votes += 1;
          option.isMyVote = true;
        }
      }),
    );

  return { polls, addPoll, getPoll, vote };
});
