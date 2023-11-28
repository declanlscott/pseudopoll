import { createEnv } from "@t3-oss/env-nuxt";
import { z } from "zod";

export const env = createEnv({
  server: {
    API_BASE_URL: z.string().url(),
    NANO_ID_ALPHABET: z.string(),
    NANO_ID_LENGTH: z.preprocess(Number, z.number().int().positive()),
  },
  client: {},
});
