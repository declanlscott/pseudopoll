import envSchema from "./schemas/env";

const env = envSchema.parse(process.env);

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },
  modules: ["@hebilicious/authjs-nuxt", "@nuxt/ui", "@pinia/nuxt"],
  runtimeConfig: {
    authJs: {
      secret: env.NUXT_AUTH_JS_SECRET,
    },
    google: {
      clientId: env.NUXT_GOOGLE_CLIENT_ID,
      clientSecret: env.NUXT_GOOGLE_CLIENT_SECRET,
    },
    public: {
      authJs: {
        // baseUrl: env.AUTH_ORIGIN,
        verifyClientOnEveryRequest: true,
      },
      promptMinLength: env.NUXT_PUBLIC_PROMPT_MIN_LENGTH,
      promptMaxLength: env.NUXT_PUBLIC_PROMPT_MIN_LENGTH,
      optionMinLength: env.NUXT_PUBLIC_OPTION_MIN_LENGTH,
      optionMaxLength: env.NUXT_PUBLIC_OPTION_MAX_LENGTH,
      minOptions: env.NUXT_PUBLIC_MIN_OPTIONS,
      maxOptions: env.NUXT_PUBLIC_MAX_OPTIONS,
      minDuration: env.NUXT_PUBLIC_MIN_DURATION,
      maxDuration: env.NUXT_PUBLIC_MAX_DURATION,
    },
    nanoId: {
      alphabet: env.NUXT_NANO_ID_ALPHABET,
      length: env.NUXT_NANO_ID_LENGTH,
    },
    api: {
      baseUrl: env.NUXT_API_BASE_URL,
    },
  },
  alias: {
    cookie: "cookie",
  },
});
