import { formatDistance } from "date-fns";

import type { Poll } from "~/types";

export default function ({ pollId }: { pollId: Poll["pollId"] }) {
  const { poll } = useQueryOptionsFactory();
  const query = useQuery(poll({ pollId }));

  let timer: ReturnType<typeof setTimeout> | null = null;
  const timeLeft = ref(0);

  function calculateTimeLeft() {
    const poll = query.data.value;

    if (!poll) {
      timeLeft.value = 0;
      return;
    }

    const now = Date.now();
    const createdAt = new Date(poll.createdAt).getTime();
    const expiresAt = createdAt + poll.duration * 1000;

    timeLeft.value = Math.floor((expiresAt - now) / 1000);
  }

  const { $mqtt } = useNuxtApp();

  onMounted(() => {
    calculateTimeLeft();
    timer = setInterval(calculateTimeLeft, 1000);

    $mqtt.subscribe(`poll/${pollId}`);
  });

  onBeforeUnmount(() => {
    if (timer) {
      clearTimeout(timer);
      timer = null;
    }

    $mqtt.unsubscribe(`poll/${pollId}`);
  });

  const totalVotes = computed(() => {
    const poll = query.data.value;

    if (!poll) {
      return 0;
    }

    return poll.options.reduce((acc, option) => acc + option.votes, 0);
  });

  const lastActivity = computed(() => {
    const poll = query.data.value;

    if (!poll) {
      return "";
    }

    const lastUpdatedAt = poll.options.reduce((lastUpdatedAt, option) => {
      if (option.updatedAt > lastUpdatedAt) {
        return option.updatedAt;
      }

      return lastUpdatedAt;
    }, poll.createdAt);

    return `Last activity ${formatDistance(
      new Date(lastUpdatedAt),
      new Date(),
      {
        addSuffix: true,
      },
    )}`;
  });

  return { query, timeLeft, totalVotes, lastActivity };
}
