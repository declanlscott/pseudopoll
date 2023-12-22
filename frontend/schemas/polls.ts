import { z } from "zod";

import type { PublicRuntimeConfig } from "nuxt/schema";

const nanoIdLength = Number(process.env.NUXT_NANO_ID_LENGTH);
const nanoIdAlphabet = process.env.NUXT_NANO_ID_ALPHABET;
const nanoIdSchema = (propertyName: string) =>
  z
    .string()
    .min(nanoIdLength, {
      message: `${propertyName} should be ${nanoIdLength} characters long.`,
    })
    .max(12, {
      message: `${propertyName} should be ${nanoIdLength} characters long.`,
    })
    .regex(new RegExp(`^[${nanoIdAlphabet}]+$`), {
      message: `${propertyName} should only contain characters from the alphabet: ${nanoIdAlphabet}.`,
    });

const durationSchema = ({ minDuration, maxDuration }: PublicRuntimeConfig) =>
  z
    .number()
    .int()
    .positive()
    .min(
      minDuration,
      `Poll duration should be at least ${minDuration} seconds.`,
    )
    .max(
      maxDuration,
      `Poll duration should be at most ${maxDuration} seconds.`,
    );

export const createPollBodySchema = (config: PublicRuntimeConfig) => {
  const {
    promptMinLength,
    promptMaxLength,
    optionMinLength,
    optionMaxLength,
    minOptions,
    maxOptions,
  } = config;

  return z.object({
    prompt: z
      .string()
      .min(
        promptMinLength,
        `Prompt should be at least ${promptMinLength} character${
          promptMinLength === 1 ? "" : "s"
        }.`,
      )
      .max(
        promptMaxLength,
        `Prompt should be at most ${promptMaxLength} characters.`,
      ),
    options: z
      .array(
        z
          .string()
          .min(
            optionMinLength,
            `Option should be at least ${optionMinLength} character${
              optionMinLength === 1 ? "" : "s"
            }.`,
          )
          .max(
            optionMaxLength,
            `Option should be at most ${optionMaxLength} characters.`,
          ),
      )
      .min(minOptions, `Poll should have at least ${minOptions} options.`)
      .max(maxOptions, `Poll should have at most ${maxOptions} options.`),
    duration: durationSchema(config),
  });
};

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

// export const updatePollDurationBodySchema = z.object({
//   duration: z.union([z.literal(-1), durationSchema]),
// });
