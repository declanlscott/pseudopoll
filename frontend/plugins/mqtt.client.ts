/* eslint-disable no-console */
import { createId } from "@paralleldrive/cuid2";
import mqtt from "mqtt";

export default defineNuxtPlugin(() => {
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
    console.log("MQTT client connected", packet);
  });

  client.on("error", (error) => {
    console.error("MQTT client error", error);
  });

  client.on("message", (topic, payload) => {
    console.log("MQTT message", topic, payload.toString());
  });

  client.on("disconnect", (packet) => {
    console.log("MQTT client disconnected", packet);
  });

  client.on("reconnect", () => {
    console.log("MQTT client reconnecting");
  });

  client.on("close", () => {
    console.log("MQTT client closed");
  });

  client.on("end", () => {
    console.log("MQTT client ended");
  });

  client.on("offline", () => {
    console.log("MQTT client offline");
  });

  return {
    provide: {
      mqtt: client,
    },
  };
});
