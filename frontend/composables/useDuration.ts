import type { Poll } from "~/openapi/types";

export default function ({ pollId }: { pollId: Poll["pollId"] }) {
  const { queryKey } = queryOptionsFactory.poll({ pollId });

  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationKey: ["duration", pollId],
    mutationFn: async ({ duration }: { duration: Poll["duration"] }) =>
      await $fetch(`/api/polls/${pollId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ duration }),
      }),
    onSuccess: ({ duration }) => {
      queryClient.setQueryData<Poll>(queryKey, (poll) =>
        poll ? { ...poll, duration } : undefined,
      );
    },
  });

  return mutation;
}
