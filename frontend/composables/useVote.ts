import type { Poll } from "~/types";

export default function ({ pollId }: { pollId: Poll["pollId"] }) {
  const { poll } = useQueryOptionsFactory();
  const { queryKey } = poll({ pollId });

  const queryClient = useQueryClient();

  const { $mqtt } = useNuxtApp();

  const mutation = useMutation({
    mutationKey: ["vote", pollId],
    mutationFn: ({
      optionId,
    }: {
      optionId: Poll["options"][number]["optionId"];
    }) =>
      $fetch(`/api/polls/${pollId}/${optionId}`, {
        method: "POST",
      }),
    onMutate: async ({ optionId }) => {
      // Cancel any outgoing refetches
      // (so they don't overwrite our optimistic update)
      await queryClient.cancelQueries({ queryKey });

      // Snapshot the previous value
      const previousPoll = queryClient.getQueryData<Poll>(queryKey);

      // Optimistically update to the new value
      queryClient.setQueryData<Poll>(queryKey, (poll) => {
        if (!poll) {
          return undefined;
        }

        const options = poll.options.map((option) => {
          if (option.optionId === optionId) {
            return { ...option, votes: option.votes + 1, isMyVote: true };
          }

          return option;
        });

        return {
          ...poll,
          options,
        };
      });

      // Return a context object with the snapshotted value
      return { previousPoll };
    },
    // If the mutation fails,
    // use the context returned from onMutate to roll back
    onError: (_error, _input, context) => {
      if (context?.previousPoll) {
        queryClient.setQueryData(queryKey, context.previousPoll);
      }
    },
    onSuccess: async ({ requestId }) => {
      await $mqtt.subscribeAsync(`vote/${requestId}`, {
        qos: 1,
      });
    },
  });

  return { mutation };
}
