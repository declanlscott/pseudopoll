import { z } from "zod";

import { env } from "~/env";

export const getPollRouterParamsSchema = z.object({
  pollId: z
    .string()
    .min(env.NANO_ID_LENGTH, {
      message: `Poll ID should be ${env.NANO_ID_LENGTH} characters long.`,
    })
    .max(12, {
      message: `Poll ID should be ${env.NANO_ID_LENGTH} characters long.`,
    })
    .regex(new RegExp(`^[${env.NANO_ID_ALPHABET}]+$`), {
      message: `Poll ID should only contain characters from the alphabet: ${env.NANO_ID_ALPHABET}.`,
    }),
});
