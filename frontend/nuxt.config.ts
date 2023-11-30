import { env } from "./env";

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },
  modules: ["@hebilicious/authjs-nuxt"],
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
    },
  },
  alias: {
    cookie: "cookie",
  },
});
