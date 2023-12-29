import { z } from "zod";

export default z.object({
  // Server only
  NUXT_API_BASE_URL: z.string().url(),
  NUXT_AUTH_JS_SECRET: z.string(),
  NUXT_GOOGLE_CLIENT_ID: z.string(),
  NUXT_GOOGLE_CLIENT_SECRET: z.string(),

  // Server and client
  NUXT_PUBLIC_NANO_ID_ALPHABET: z.string(),
  NUXT_PUBLIC_NANO_ID_LENGTH: z.preprocess(Number, z.number().int().positive()),
  NUXT_PUBLIC_PROMPT_MIN_LENGTH: z.preprocess(
    Number,
    z.number().int().positive(),
  ),
  NUXT_PUBLIC_PROMPT_MAX_LENGTH: z.preprocess(
    Number,
    z.number().int().positive(),
  ),
  NUXT_PUBLIC_OPTION_MIN_LENGTH: z.preprocess(
    Number,
    z.number().int().positive(),
  ),
  NUXT_PUBLIC_OPTION_MAX_LENGTH: z.preprocess(
    Number,
    z.number().int().positive(),
  ),
  NUXT_PUBLIC_MIN_OPTIONS: z.preprocess(Number, z.number().int().positive()),
  NUXT_PUBLIC_MAX_OPTIONS: z.preprocess(Number, z.number().int().positive()),
  NUXT_PUBLIC_MIN_DURATION: z.preprocess(Number, z.number().int().positive()),
  NUXT_PUBLIC_MAX_DURATION: z.preprocess(Number, z.number().int().positive()),
});
