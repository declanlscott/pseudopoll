import type { Poll } from "~/types";

export default function ({ pollId }: { pollId: Poll["pollId"] }) {
  const { poll, myPolls } = useQueryOptionsFactory();
  const { queryKey } = poll({ pollId });

  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationKey: ["archive", pollId],
    mutationFn: async ({ value }: { value: Poll["isArchived"] }) =>
      await $fetch(`/api/polls/${pollId}/archive`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ value }),
      }),
    onMutate: async ({ value: isArchived }) => {
      // Cancel any outgoing refetches
      // (so they don't overwrite our optimistic update)
      await queryClient.cancelQueries({ queryKey });

      // Snapshot the previous value
      const previousPoll = queryClient.getQueryData<Poll>(queryKey);

      // Optimistically update to the new value
      queryClient.setQueryData<Poll>(queryKey, (poll) =>
        poll ? { ...poll, isArchived } : undefined,
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
    onSettled: () =>
      queryClient.invalidateQueries({ queryKey: myPolls.queryKey }),
  });

  return { mutation };
}
