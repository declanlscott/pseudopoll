import { createPollBodySchema } from "~/schemas/polls";

// eslint-disable-next-line import/order
import type { z } from "zod";

export default function () {
  const config = useRuntimeConfig();
  const createPollSchema = createPollBodySchema(config.public);
  type CreatePollSchema = z.infer<typeof createPollSchema>;

  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: ({ poll }: { poll: CreatePollSchema }) =>
      $fetch("/api/polls", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(poll),
      }),
    onSuccess: (poll) =>
      queryClient.setQueryData(
        queryOptionsFactory.poll({ pollId: poll.pollId }).queryKey,
        poll,
      ),
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