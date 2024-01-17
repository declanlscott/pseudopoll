import {
  array,
  boolean,
  integer,
  intersect,
  literal,
  maxLength,
  maxValue,
  minLength,
  minValue,
  number,
  object,
  regex,
  string,
  union,
} from "valibot";

import type { PublicRuntimeConfig } from "nuxt/schema";

const pluralize = (n: number, singular: string) =>
  `${n} ${n === 1 ? singular : `${singular}s`}`;

const nanoIdSchema = ({ nanoId }: PublicRuntimeConfig) =>
  string([
    minLength(
      nanoId.length,
      `ID should be ${pluralize(nanoId.length, "character")} long`,
    ),
    maxLength(
      nanoId.length,
      `ID should be ${pluralize(nanoId.length, "character")} long`,
    ),
    regex(
      new RegExp(`^[${nanoId.alphabet}]+$`),
      `ID should only contain characters from the alphabet: ${nanoId.alphabet}`,
    ),
  ]);

const durationSchema = ({ minDuration, maxDuration }: PublicRuntimeConfig) =>
  number([
    integer(),
    minValue(
      minDuration,
      `Poll duration should be at least ${pluralize(minDuration, "second")}`,
    ),
    maxValue(
      maxDuration,
      `Poll duration should be at most ${pluralize(maxDuration, "second")}`,
    ),
  ]);

export const createPollSchema = (config: PublicRuntimeConfig) =>
  object({
    prompt: string([
      minLength(
        config.promptMinLength,
        `Prompt should be at least ${pluralize(config.promptMinLength, "character")}`,
      ),
      maxLength(
        config.promptMaxLength,
        `Prompt should be at most ${pluralize(config.promptMaxLength, "character")}`,
      ),
    ]),
    options: array(
      string([
        minLength(
          config.optionMinLength,
          `Option should be at least ${pluralize(config.optionMinLength, "character")}`,
        ),
        maxLength(
          config.optionMaxLength,
          `Option should be at most ${pluralize(config.optionMaxLength, "character")}`,
        ),
      ]),
      [
        minLength(
          config.minOptions,
          `Poll should have at least ${pluralize(config.minOptions, "option")}`,
        ),
        maxLength(
          config.maxOptions,
          `Poll should have at most ${pluralize(config.maxOptions, "option")}`,
        ),
      ],
    ),
    duration: durationSchema(config),
  });

export const pollParamsSchema = (config: PublicRuntimeConfig) =>
  object({
    pollId: nanoIdSchema(config),
  });

export const voteParamsSchema = (config: PublicRuntimeConfig) =>
  intersect([
    pollParamsSchema(config),
    object({ optionId: nanoIdSchema(config) }),
  ]);

export const archiveSchema = object({
  isArchived: boolean(),
});

export const updateDurationSchema = (config: PublicRuntimeConfig) =>
  object({
    duration: union([literal(-1), durationSchema(config)]),
  });
