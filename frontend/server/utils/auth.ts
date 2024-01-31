import GoogleProvider from "@auth/core/providers/google";
import { getServerSession } from "#auth";

import type { JWT } from "@auth/core/jwt";
import type { AuthConfig } from "@auth/core/types";
import type { EventHandlerRequest, H3Event } from "h3";

declare module "@auth/core/types" {
  interface User {
    id: string;
    idToken: string;
    refreshToken: string;
    expiresAt: number;
  }
  interface Session {
    user: User;
    id: string;
  }
}

const runtimeConfig = useRuntimeConfig();

export const authOptions: AuthConfig = {
  secret: runtimeConfig.authJs.secret,
  providers: [
    GoogleProvider({
      clientId: runtimeConfig.google.clientId,
      clientSecret: runtimeConfig.google.clientSecret,
      authorization: {
        params: {
          prompt: "consent",
          access_type: "offline",
          response_type: "code",
        },
      },
    }),
  ],
  callbacks: {
    // Whitelist users based on their oauth id, if enabled
    signIn({ account }) {
      if (!account) {
        return false;
      }

      if (!runtimeConfig.whitelist.enabled) {
        return true;
      }

      if (!runtimeConfig.whitelist.users.includes(account.providerAccountId)) {
        return false;
      }

      return true;
    },
    jwt({ account, user, token }) {
      // Initial sign in
      if (account && user) {
        return {
          ...token,
          idToken: account.id_token,
          refreshToken: account.refresh_token,
          expiresAt: account.expires_at,
        };
      }

      // Return previous token if the token has not expired yet
      if (Math.floor(Date.now() / 1000) < (token.expiresAt as number)) {
        return token;
      }

      // Token has expired, try to update it
      return refreshJwt(token);
    },
    session(params) {
      const { session, token } = params;
      if (session.user) {
        session.user.id = token.sub as string;
        session.user.idToken = token.idToken as string;
        session.user.refreshToken = token.refreshToken as string;
        session.user.expiresAt = token.expiresAt as number;
      }

      return session;
    },
  },
};

export const getServerAuthSession = (event: H3Event<EventHandlerRequest>) =>
  getServerSession(event, authOptions);

async function refreshJwt(jwt: JWT) {
  const url = new URL("https:///oauth2.googleapis.com/token");
  url.searchParams.set("client_id", runtimeConfig.google.clientId);
  url.searchParams.set("client_secret", runtimeConfig.google.clientSecret);
  url.searchParams.set("refresh_token", jwt.refreshToken as string);
  url.searchParams.set("grant_type", "refresh_token");

  const response = await fetch(url.toString(), {
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    method: "POST",
  });

  const refreshedTokens = await response.json();

  if (!response.ok) {
    throw createError({
      statusCode: 401,
      message: "RefreshJwtError",
    });
  }

  return {
    ...jwt,
    idToken: refreshedTokens.id_token,
    refreshToken: refreshedTokens.refresh_token ?? jwt.refreshToken, // Fall back to old refresh token
    expiresAt: Math.floor(
      (Date.now() + refreshedTokens.expires_in * 1000) / 1000,
    ),
  };
}
