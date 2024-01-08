import type { Poll } from "~/openapi/types";

export default function ({ pollId }: { pollId: Poll["pollId"] }) {
  const { queryKey } = useQueryOptionsFactory().poll({ pollId });

  const queryClient = useQueryClient();

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
      queryClient.setQueryData<Poll>(queryKey, (poll) =>
        poll
          ? {
              ...poll,
              options: poll.options.map((option) =>
                option.optionId === optionId
                  ? { ...option, votes: option.votes + 1, isMyVote: true }
                  : option,
              ),
            }
          : undefined,
      );

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
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    onSuccess: ({ requestId }) => {
      // TODO: Subscribe to requestId channel and wait for response
    },
  });

  return mutation;
}
