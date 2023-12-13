import { z } from "zod";

import { env } from "~/env";

const nanoIdSchema = (propertyName: string) =>
  z
    .string()
    .min(env.NANO_ID_LENGTH, {
      message: `${propertyName} should be ${env.NANO_ID_LENGTH} characters long.`,
    })
    .max(12, {
      message: `${propertyName} should be ${env.NANO_ID_LENGTH} characters long.`,
    })
    .regex(new RegExp(`^[${env.NANO_ID_ALPHABET}]+$`), {
      message: `${propertyName} should only contain characters from the alphabet: ${env.NANO_ID_ALPHABET}.`,
    });

// TODO: Get min and max values from env
export const createPollBodySchema = z.object({
  prompt: z
    .string()
    .min(1, "Prompt should be at least 1 character.")
    .max(280, "Prompt should be at most 280 characters."),
  options: z
    .array(
      z
        .string()
        .min(1, "Option should be at least 1 character.")
        .max(140, "Option should be at most 140 characters."),
    )
    .min(2, "Poll should have at least 2 options.")
    .max(10, "Poll should have at most 10 options."),
  duration: z
    .number()
    .int()
    .positive()
    .min(60, "Poll duration should be at least 60 seconds.")
    .max(604800, "Poll duration should be at most 604800 seconds."),
});

export const getPollRouterParamsSchema = z.object({
  pollId: nanoIdSchema("Poll ID"),
});

export const voteRouterParamsSchema = z.object({
  pollId: nanoIdSchema("Poll ID"),
  optionId: nanoIdSchema("Option ID"),
});

export const archivePollRouterParamsSchema = z.object({
  pollId: nanoIdSchema("Poll ID"),
});

export const archivePollBodySchema = z.object({
  archived: z.boolean(),
});

export const updatePollDurationRouterParamsSchema = z.object({
  pollId: nanoIdSchema("Poll ID"),
});

export const updatePollDurationBodySchema = z.object({
  duration: z.union([z.literal(-1), z.number().int().positive()]),
});
