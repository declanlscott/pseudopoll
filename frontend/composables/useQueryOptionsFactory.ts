import { queryOptions } from "@tanstack/vue-query";

import type { Poll } from "~/openapi/types";

export default function () {
  const headers = useRequestHeaders();

  const queryOptionsFactory = {
    poll: ({ pollId }: { pollId: Poll["pollId"] }) =>
      queryOptions({
        // eslint-disable-next-line @tanstack/query/exhaustive-deps
        queryKey: ["poll", pollId] as const,
        queryFn: async ({ queryKey }) =>
          await $fetch(`/api/polls/${queryKey[1]}`, {
            method: "GET",
            headers,
          }),
        staleTime: Infinity,
      }),
  };

  return queryOptionsFactory;
}
