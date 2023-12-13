import { createEnv } from "@t3-oss/env-nuxt";
import { z } from "zod";

export const env = createEnv({
  server: {
    API_BASE_URL: z.string().url(),
    AUTH_SECRET: z.string(),
    GOOGLE_OAUTH_CLIENT_ID: z.string(),
    GOOGLE_OAUTH_CLIENT_SECRET: z.string(),
    NANO_ID_ALPHABET: z.string(),
    NANO_ID_LENGTH: z.preprocess(Number, z.number().int().positive()),
    PROMPT_MIN_LENGTH: z.preprocess(Number, z.number().int().positive()),
    PROMPT_MAX_LENGTH: z.preprocess(Number, z.number().int().positive()),
    OPTION_MIN_LENGTH: z.preprocess(Number, z.number().int().positive()),
    OPTION_MAX_LENGTH: z.preprocess(Number, z.number().int().positive()),
    MIN_OPTIONS: z.preprocess(Number, z.number().int().positive()),
    MAX_OPTIONS: z.preprocess(Number, z.number().int().positive()),
    MIN_DURATION: z.preprocess(Number, z.number().int().positive()),
    MAX_DURATION: z.preprocess(Number, z.number().int().positive()),
  },
  client: {},
});
