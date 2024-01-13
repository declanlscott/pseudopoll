/* eslint-disable @tanstack/query/exhaustive-deps */
import { queryOptions } from "@tanstack/vue-query";

import type { Poll } from "~/types";

export default function () {
  const headers = useRequestHeaders();

  const queryOptionsFactory = {
    poll: ({ pollId }: { pollId: Poll["pollId"] }) =>
      queryOptions({
        queryKey: ["poll", pollId] as const,
        queryFn: async ({ queryKey }) =>
          await $fetch(`/api/polls/${queryKey[1]}`, {
            method: "GET",
            headers,
          }),
        staleTime: Infinity,
      }),
    myPolls: queryOptions({
      queryKey: ["myPolls"] as const,
      queryFn: async () =>
        await $fetch("/api/polls", {
          method: "GET",
          headers,
        }),
      staleTime: Infinity,
    }),
  };

  return queryOptionsFactory;
}
