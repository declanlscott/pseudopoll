import { z } from "zod";

import type { PublicRuntimeConfig } from "nuxt/schema";

const nanoIdSchema = ({ nanoId }: PublicRuntimeConfig, propertyName: string) =>
  z
    .string()
    .min(nanoId.length, {
      message: `${propertyName} should be ${nanoId.length} characters long.`,
    })
    .max(12, {
      message: `${propertyName} should be ${nanoId.length} characters long.`,
    })
    .regex(new RegExp(`^[${nanoId.alphabet}]+$`), {
      message: `${propertyName} should only contain characters from the alphabet: ${nanoId.alphabet}.`,
    });

const durationSchema = ({ minDuration, maxDuration }: PublicRuntimeConfig) =>
  z.coerce
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

export const getPollRouterParamsSchema = (config: PublicRuntimeConfig) =>
  z.object({
    pollId: nanoIdSchema(config, "Poll ID"),
  });

export const voteRouterParamsSchema = (config: PublicRuntimeConfig) =>
  z.object({
    pollId: nanoIdSchema(config, "Poll ID"),
    optionId: nanoIdSchema(config, "Option ID"),
  });

export const archivePollRouterParamsSchema = (config: PublicRuntimeConfig) =>
  z.object({
    pollId: nanoIdSchema(config, "Poll ID"),
  });

export const archivePollBodySchema = z.object({
  archived: z.boolean(),
});

export const updatePollDurationRouterParamsSchema = (
  config: PublicRuntimeConfig,
) =>
  z.object({
    pollId: nanoIdSchema(config, "Poll ID"),
  });

export const updatePollDurationBodySchema = (config: PublicRuntimeConfig) =>
  z.object({
    duration: z.union([z.literal(-1), durationSchema(config)]),
  });
