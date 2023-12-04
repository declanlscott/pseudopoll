// eslint-disable-next-line import/named
import { getServerSession } from "#auth";

import { getPollRouterParamsSchema } from "~/schemas/polls";
import { authOptions } from "~/server/auth";
import fetch from "~/server/fetch";

export default defineEventHandler(async (event) => {
  const routerParams = await getValidatedRouterParams(
    event,
    getPollRouterParamsSchema.safeParse,
  );

  if (!routerParams.success) {
    throw createError({
      statusCode: 400,
      message: routerParams.error.message,
    });
  }

  const { pollId } = routerParams.data;

  const session = await getServerSession(event, authOptions);
  const poll = await fetch.GET(
    session ? "/polls/{pollId}" : "/public/polls/{pollId}",
    {
      params: {
        path: { pollId },
      },
      headers: session
        ? { Authorization: `Bearer ${session.user.idToken}` }
        : {},
    },
  );

  if (poll.error) {
    throw createError({
      statusCode: poll.response.status,
      message: `${poll.error.message}. ${poll.error.cause}`,
    });
  }

  return poll.data;
});
