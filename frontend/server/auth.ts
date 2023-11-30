import GoogleProvider from "@auth/core/providers/google";
import { getServerSession } from "#auth";

import type { AuthConfig } from "@auth/core/types";
import type { H3Event, EventHandlerRequest } from "h3";

declare module "@auth/core/types" {
  interface Session {
    user: User;
  }
  interface User {
    id: string;
    idToken: string;
  }
}

const runtimeConfig = useRuntimeConfig();

export const authOptions: AuthConfig = {
  secret: runtimeConfig.authJs.secret,
  providers: [
    GoogleProvider({
      clientId: runtimeConfig.google.clientId,
      clientSecret: runtimeConfig.google.clientSecret,
    }),
  ],
  callbacks: {
    async session(params) {
      const { session, token, user } = params;
      if (session.user) {
        session.user.id = token.sub as string;
        session.user.idToken = token.idToken as string;
      }

      return session;
    },
    async jwt(params) {
      const { account, token } = params;
      if (account) {
        token.idToken = account.id_token;
      }

      return params.token;
    },
  },
};

export const getServerAuthSession = (event: H3Event<EventHandlerRequest>) =>
  getServerSession(event, authOptions);
