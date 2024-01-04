import type { Poll } from "~/openapi/types";

export default function ({ pollId }: { pollId: Poll["pollId"] }) {
  const poll = useNuxtData<Poll>(`poll/${pollId}`);

  const isSubmitting = ref(false);
  const error = ref<Error | null>(null);

  async function closeNow() {
    error.value = null;
    isSubmitting.value = true;

    try {
      // Make duration update request
      const { data, error } = await useAsyncData(`duration/${pollId}`, () =>
        $fetch(`/api/polls/${pollId}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ duration: -1 }),
        }),
      );

      if (error.value) {
        throw error.value;
      }

      if (data.value) {
        if (poll.data.value) {
          // Update poll duration in cache
          poll.data.value.duration = data.value.duration;
        }
      }
    } catch (err: any) {
      if (isNuxtError(err) || isError(err)) {
        error.value = err;
      } else {
        error.value = {
          name: "Error",
          message: "An unknown error occurred.",
        };
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  return { closeNow, isSubmitting, error };
}
