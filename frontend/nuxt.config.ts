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
      PROMPT_MIN_LENGTH: env.PROMPT_MIN_LENGTH,
      PROMPT_MAX_LENGTH: env.PROMPT_MAX_LENGTH,
      OPTION_MIN_LENGTH: env.OPTION_MIN_LENGTH,
      OPTION_MAX_LENGTH: env.OPTION_MAX_LENGTH,
      MIN_OPTIONS: env.MIN_OPTIONS,
      MAX_OPTIONS: env.MAX_OPTIONS,
      MIN_DURATION: env.MIN_DURATION,
      MAX_DURATION: env.MAX_DURATION,
    },
  },
  alias: {
    cookie: "cookie",
  },
});
