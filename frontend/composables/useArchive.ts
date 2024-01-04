import type { Poll } from "~/openapi/types";

export default function ({ pollId }: { pollId: Poll["pollId"] }) {
  const poll = useNuxtData<Poll>(`poll/${pollId}`);

  const isSubmitting = ref(false);
  const error = ref<Error | null>(null);

  async function archive({ isArchived }: { isArchived: Poll["isArchived"] }) {
    error.value = null;
    isSubmitting.value = true;

    try {
      // Optimistic update
      if (poll.data.value) {
        poll.data.value.isArchived = isArchived;
      }

      // Make archive request
      const { error } = await useAsyncData(`archive/${pollId}`, () =>
        $fetch(`/api/polls/${pollId}`, {
          method: "DELETE",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ isArchived }),
        }),
      );

      // Rollback optimistic update on error
      if (error.value) {
        if (poll.data.value) {
          poll.data.value.isArchived = !isArchived;
        }

        throw error.value;
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

  return { archive, isSubmitting, error };
}
