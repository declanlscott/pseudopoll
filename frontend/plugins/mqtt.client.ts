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

  client.on("connect", (packet) => {
    console.log(
      "MQTT client connected",
      new Date().toLocaleString("en-US", {
        timeZone: "America/Chicago",
      }),
      packet,
    );
  });

  client.on("error", (error) => {
    console.error(
      "MQTT client error",
      new Date().toLocaleString("en-US", {
        timeZone: "America/Chicago",
      }),
      error,
    );
  });

  client.on("message", (fullTopic, payloadBuffer) => {
    console.log("topic", fullTopic);

    const payload = JSON.parse(
      new TextDecoder("utf8").decode(new Uint8Array(payloadBuffer)),
    ) as Payload;
    console.log("payload", payload);

    const segments = fullTopic.split("/");
    const topic = segments[0];
    const topicId = segments[1];
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

            return {
              ...poll,
              options: poll.options.map((option) => {
                if (option.optionId === payload.data.optionId) {
                  return {
                    ...option,
                    votes: payload.data.votes,
                    updatedAt: payload.data.updatedAt,
                  };
                }

                return option;
              }),
            };
          });

          break;
        }

        if (payload.type === "pollModified") {
          const { queryKey } = poll({ pollId: payload.data.pollId });

          queryClient.setQueryData<Poll>(queryKey, (poll) => {
            if (!poll) {
              return undefined;
            }

            return { ...poll, ...payload.data };
          });

          break;
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

          break;
        }

        break;
      default:
        console.log("Unknown topic", topic);
    }
  });

  client.on("disconnect", (packet) => {
    console.log(
      "MQTT client disconnected",
      new Date().toLocaleString("en-US", {
        timeZone: "America/Chicago",
      }),
      packet,
    );
  });

  client.on("reconnect", () => {
    console.log(
      "MQTT client reconnecting",
      new Date().toLocaleString("en-US", {
        timeZone: "America/Chicago",
      }),
    );
  });

  client.on("close", () => {
    console.log(
      "MQTT client closed",
      new Date().toLocaleString("en-US", {
        timeZone: "America/Chicago",
      }),
    );

    client.reconnect();
  });

  client.on("end", () => {
    console.log(
      "MQTT client ended",
      new Date().toLocaleString("en-US", {
        timeZone: "America/Chicago",
      }),
    );
  });

  client.on("offline", () => {
    console.log(
      "MQTT client offline",
      new Date().toLocaleString("en-US", {
        timeZone: "America/Chicago",
      }),
    );
  });

  return {
    provide: {
      mqtt: client,
    },
  };
});
