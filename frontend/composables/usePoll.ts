import { formatDistance } from "date-fns";

import type { Poll } from "~/types";

export default function ({ pollId }: { pollId: Poll["pollId"] }) {
  const { poll } = useQueryOptionsFactory();
  const query = useQuery(poll({ pollId }));

  let timer: ReturnType<typeof setTimeout> | null = null;
  const time = reactive({
    left: 0,
    lastActivity: "",
    duration: 0,
  });

  function calculateTime() {
    const poll = query.data.value;

    if (!poll) {
      time.left = 0;
      time.lastActivity = "";
      time.duration = 0;
      return;
    }

    const now = Date.now();
    const createdAt = new Date(poll.createdAt).getTime();
    const expiresAt = createdAt + poll.duration * 1000;
    time.left = Math.floor((expiresAt - now) / 1000);

    const lastUpdatedAt = poll.options.reduce((lastUpdatedAt, option) => {
      if (option.updatedAt > lastUpdatedAt) {
        return option.updatedAt;
      }

      return lastUpdatedAt;
    }, poll.createdAt);
    time.lastActivity = `Last activity ${formatDistance(
      new Date(lastUpdatedAt),
      new Date(),
      { addSuffix: true },
    )}`;

    time.duration = poll.duration;
  }

  const { $mqtt } = useNuxtApp();

  onMounted(() => {
    calculateTime();
    timer = setInterval(calculateTime, 1000);

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

  return { query, time, totalVotes };
}
