import type { Output } from "valibot";
import type { Poll } from "~/types";

export default function () {
  const queryClient = useQueryClient();

  const { poll, myPolls } = useQueryOptionsFactory();

  const config = useRuntimeConfig();
  const schema = createPollSchema(config.public);
  const mutation = useMutation({
    mutationFn: ({ poll }: { poll: Output<typeof schema> }) =>
      $fetch("/api/polls", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(poll),
      }),
    onSuccess: (data) =>
      queryClient.setQueryData<Poll>(
        poll({ pollId: data.pollId }).queryKey,
        data,
      ),
    onSettled: () =>
      queryClient.invalidateQueries({ queryKey: myPolls.queryKey }),
  });

  const durations = [
    { label: "1 minute", value: 60 },
    { label: "5 minutes", value: 300 },
    { label: "15 minutes", value: 900 },
    { label: "30 minutes", value: 1800 },
    { label: "1 hour", value: 3600 },
    { label: "2 hours", value: 7200 },
    { label: "6 hours", value: 21600 },
    { label: "12 hours", value: 43200 },
    { label: "1 day", value: 86400 },
    { label: "2 days", value: 172800 },
    { label: "3 days", value: 259200 },
    { label: "1 week", value: 604800 },
  ];

  return { mutation, durations };
}
