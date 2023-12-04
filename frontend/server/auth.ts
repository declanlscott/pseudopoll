import GoogleProvider from "@auth/core/providers/google";
// eslint-disable-next-line import/named
import { getServerSession } from "#auth";

import type { AuthConfig } from "@auth/core/types";
import type { EventHandlerRequest, H3Event } from "h3";

declare module "@auth/core/types" {
  interface User {
    id: string;
    idToken: string;
  }
  interface Session {
    user: User;
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
    session(params) {
      const { session, token } = params;
      if (session.user) {
        session.user.id = token.sub as string;
        session.user.idToken = token.idToken as string;
      }

      return session;
    },
    jwt(params) {
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
