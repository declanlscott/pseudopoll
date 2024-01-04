import type { Poll } from "~/openapi/types";

export default function ({ pollId }: { pollId: Poll["pollId"] }) {
  const poll = useNuxtData<Poll>(`poll/${pollId}`);

  const router = useRouter();

  const isSubmitting = ref(false);
  const error = ref<Error | null>(null);

  async function vote({
    optionId,
  }: {
    optionId: Poll["options"][number]["optionId"];
  }) {
    error.value = null;
    isSubmitting.value = true;

    try {
      // Prevent double submission
      if (poll.data.value?.options.some((option) => option.isMyVote)) {
        throw createError({
          message: "You have already voted on this poll.",
        });
      }

      // Optimistic update
      if (poll.data.value) {
        poll.data.value.options.forEach((option) => {
          if (option.optionId === optionId) {
            option.votes += 1;
            option.isMyVote = true;
          }
        });
      }

      // Make vote request
      const { data, error } = await useAsyncData(
        `vote/${pollId}/${optionId}`,
        () =>
          $fetch(`/api/polls/${pollId}/${optionId}`, {
            method: "POST",
          }),
      );

      // Rollback optimistic update on error
      if (error.value) {
        if (poll.data.value) {
          poll.data.value.options.forEach((option) => {
            if (option.optionId === optionId) {
              option.votes -= 1;
              option.isMyVote = false;
            }
          });
        }

        throw error.value;
      }

      if (data.value) {
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const channel = data.value.requestId;

        // TODO: Subscribe to channel and wait for response

        // Redirect to results page
        router.push(`/${pollId}/results`);
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

  return { vote, isSubmitting, error };
}
