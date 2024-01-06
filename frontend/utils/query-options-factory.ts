import { queryOptions } from "@tanstack/vue-query";

import type { Poll } from "~/openapi/types";

export default {
  poll: ({ pollId }: { pollId: Poll["pollId"] }) =>
    queryOptions({
      queryKey: ["poll", pollId] as const,
      queryFn: async ({ queryKey }) =>
        await $fetch(`/api/polls/${queryKey[1]}`, {
          method: "GET",
        }),
      staleTime: Infinity,
    }),
};
