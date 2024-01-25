import { parse } from "valibot";

import envSchema from "./schemas/env";

const env = parse(envSchema, process.env);

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },
  modules: [
    "@nuxtjs/eslint-module",
    "@hebilicious/authjs-nuxt",
    "@hebilicious/vue-query-nuxt",
    "@nuxt/ui",
  ],
  ui: {
    icons: ["lucide"],
  },
  runtimeConfig: {
    authJs: {
      secret: env.NUXT_AUTH_JS_SECRET,
    },
    google: {
      clientId: env.NUXT_GOOGLE_CLIENT_ID,
      clientSecret: env.NUXT_GOOGLE_CLIENT_SECRET,
    },
    whitelist: {
      enabled: env.NUXT_WHITELIST_ENABLED,
      users: env.NUXT_WHITELIST_USERS,
    },
    public: {
      authJs: {
        baseUrl: env.NUXT_PUBLIC_AUTH_JS_BASE_URL,
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
      nanoId: {
        alphabet: env.NUXT_PUBLIC_NANO_ID_ALPHABET,
        length: env.NUXT_PUBLIC_NANO_ID_LENGTH,
      },
      iot: {
        endpoint: env.NUXT_PUBLIC_IOT_ENDPOINT,
        customAuthorizerName: env.NUXT_PUBLIC_IOT_CUSTOM_AUTHORIZER_NAME,
      },
    },
    api: {
      baseUrl: env.NUXT_API_BASE_URL,
    },
  },
  alias: {
    cookie: "cookie",
  },
  imports: {
    dirs: ["./schemas"],
  },
  nitro: {
    imports: {
      dirs: ["./schemas"],
    },
  },
});
