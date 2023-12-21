import { env } from "./env";

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },
  modules: ["@hebilicious/authjs-nuxt", "@nuxt/ui"],
  runtimeConfig: {
    authJs: {
      secret: env.AUTH_SECRET,
    },
    google: {
      clientId: env.GOOGLE_OAUTH_CLIENT_ID,
      clientSecret: env.GOOGLE_OAUTH_CLIENT_SECRET,
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
  },
  alias: {
    cookie: "cookie",
  },
});
