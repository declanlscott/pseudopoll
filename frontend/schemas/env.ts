import { z } from "zod";

export default z.object({
  // Server only
  NUXT_API_BASE_URL: z.string().url(),
  NUXT_AUTH_JS_SECRET: z.string(),
  NUXT_GOOGLE_CLIENT_ID: z.string(),
  NUXT_GOOGLE_CLIENT_SECRET: z.string(),
  NUXT_WHITELIST_ENABLED: z.coerce.boolean(),
  NUXT_WHITELIST_USERS: z.string().transform((csv) => csv.split(",")),

  // Server and client
  NUXT_PUBLIC_NANO_ID_ALPHABET: z.string(),
  NUXT_PUBLIC_NANO_ID_LENGTH: z.coerce.number().int().positive(),
  NUXT_PUBLIC_PROMPT_MIN_LENGTH: z.coerce.number().int().positive(),
  NUXT_PUBLIC_PROMPT_MAX_LENGTH: z.coerce.number().int().positive(),
  NUXT_PUBLIC_OPTION_MIN_LENGTH: z.coerce.number().int().positive(),
  NUXT_PUBLIC_OPTION_MAX_LENGTH: z.coerce.number().int().positive(),
  NUXT_PUBLIC_MIN_OPTIONS: z.coerce.number().int().positive(),
  NUXT_PUBLIC_MAX_OPTIONS: z.coerce.number().int().positive(),
  NUXT_PUBLIC_MIN_DURATION: z.coerce.number().int().positive(),
  NUXT_PUBLIC_MAX_DURATION: z.coerce.number().int().positive(),
  NUXT_PUBLIC_IOT_ENDPOINT: z.string(),
  NUXT_PUBLIC_IOT_CUSTOM_AUTHORIZER_NAME: z.string(),
});
