import type { Poll } from "~/openapi/types";

export default async function ({ pollId }: { pollId: Poll["pollId"] }) {
  const nuxtApp = useNuxtApp();

  const data = await useAsyncData(
    `poll/${pollId}`,
    () =>
      $fetch(`/api/polls/${pollId}`, {
        method: "GET",
        headers: useRequestHeaders(),
      }),
    {
      getCachedData: (key) =>
        (nuxtApp.payload.data[key] || nuxtApp.static.data[key]) as Poll,
    },
  );

  return data;
}
