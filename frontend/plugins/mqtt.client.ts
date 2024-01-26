/* eslint-disable no-console */
import { createId } from "@paralleldrive/cuid2";
import mqtt from "mqtt";

import type { Payload, Poll } from "~/types";

export default defineNuxtPlugin(() => {
  const queryClient = useQueryClient();

  const { poll } = useQueryOptionsFactory();

  const clientId = `client-${createId()}`;

  const { endpoint, customAuthorizerName } = useRuntimeConfig().public.iot;
  const brokerUrl = new URL(`wss://${endpoint}/mqtt`);
  brokerUrl.searchParams.set(
    "x-amz-customauthorizer-name",
    customAuthorizerName,
  );

  const client = mqtt.connect(brokerUrl.toString(), {
    clientId,
    reconnectPeriod: 0,
  });

  client.on("connect", () => {
    log("MQTT client connected");
  });

  client.on("error", (error) => {
    log("MQTT client error", error);
  });

  client.on("message", (fullTopic, payloadBuffer) => {
    log("message topic", undefined, fullTopic);

    const payload = JSON.parse(
      new TextDecoder("utf8").decode(new Uint8Array(payloadBuffer)),
    ) as Payload;
    log("message payload", undefined, payload);

    const [topic, topicId] = fullTopic.split("/");
    switch (topic) {
      case "poll":
        if (payload.type === "voteCounted") {
          const { queryKey } = poll({ pollId: payload.data.pollId });

          queryClient.setQueryData<Poll>(queryKey, (poll) => {
            if (!poll) {
              return undefined;
            }

            const lastUpdatedAt = poll.options.reduce(
              (lastUpdatedAt, option) => {
                if (option.updatedAt > lastUpdatedAt) {
                  return option.updatedAt;
                }

                return lastUpdatedAt;
              },
              poll.createdAt,
            );

            if (lastUpdatedAt > payload.data.updatedAt) {
              return poll;
            }

            const options = poll.options.map((option) => {
              if (option.optionId === payload.data.optionId) {
                return {
                  ...option,
                  votes: payload.data.votes,
                  updatedAt: payload.data.updatedAt,
                };
              }

              return option;
            });

            return {
              ...poll,
              options,
            };
          });
        }

        if (payload.type === "pollModified") {
          const { queryKey } = poll({ pollId: payload.data.pollId });

          queryClient.setQueryData<Poll>(queryKey, (poll) => {
            if (!poll) {
              return undefined;
            }

            return { ...poll, ...payload.data };
          });
        }

        break;
      case "vote":
        if (payload.type === "voteSucceeded" || payload.type === "voteFailed") {
          const isSuccessful = payload.type === "voteSucceeded";

          const { queryKey } = poll({ pollId: payload.data.pollId });

          queryClient.setQueryData<Poll>(queryKey, (poll) => {
            if (!poll) {
              return undefined;
            }

            return {
              ...poll,
              options: poll.options.map((option) => {
                if (option.optionId === payload.data.optionId) {
                  return {
                    ...option,
                    votes: isSuccessful ? option.votes : option.votes - 1,
                    isMyVote: isSuccessful,
                  };
                }

                return option;
              }),
            };
          });

          client.unsubscribe(`vote/${topicId}`);
        }

        break;
      default:
        log("Unknown topic", undefined, topic);
    }
  });

  client.on("disconnect", () => {
    log("MQTT client disconnected");
  });

  client.on("reconnect", () => {
    log("MQTT client reconnecting");
  });

  client.on("close", () => {
    log("MQTT client closed");
    client.reconnect();
  });

  client.on("end", () => {
    log("MQTT client ended");
  });

  client.on("offline", () => {
    log("MQTT client offline");
  });

  return {
    provide: {
      mqtt: client,
    },
  };
});

function log(message: string, error?: Error, ...args: unknown[]) {
  if (import.meta.env.PROD) {
    return;
  }

  if (error) {
    if (args.length) {
      console.error(message, args, error);
      return;
    }

    console.error(message, error);
    return;
  }

  if (args.length) {
    console.log(message, args);
    return;
  }

  console.log(message);
}
