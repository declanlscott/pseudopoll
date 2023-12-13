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

const durationSchema = z
  .number()
  .int()
  .positive()
  .min(
    env.MIN_DURATION,
    `Poll duration should be at least ${env.MIN_DURATION} seconds.`,
  )
  .max(
    env.MAX_DURATION,
    `Poll duration should be at most ${env.MAX_DURATION} seconds.`,
  );

export const createPollBodySchema = z.object({
  prompt: z
    .string()
    .min(
      env.PROMPT_MIN_LENGTH,
      `Prompt should be at least ${env.PROMPT_MIN_LENGTH} characters.`,
    )
    .max(
      env.PROMPT_MAX_LENGTH,
      `Prompt should be at most ${env.PROMPT_MAX_LENGTH} characters.`,
    ),
  options: z
    .array(
      z
        .string()
        .min(
          env.OPTION_MIN_LENGTH,
          `Option should be at least ${env.OPTION_MIN_LENGTH} characters.`,
        )
        .max(
          env.OPTION_MAX_LENGTH,
          `Option should be at most ${env.OPTION_MAX_LENGTH} characters.`,
        ),
    )
    .min(
      env.MIN_OPTIONS,
      `Poll should have at least ${env.MIN_OPTIONS} options.`,
    )
    .max(
      env.MAX_OPTIONS,
      `Poll should have at most ${env.MAX_OPTIONS} options.`,
    ),
  duration: durationSchema,
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
  duration: z.union([z.literal(-1), durationSchema]),
});
