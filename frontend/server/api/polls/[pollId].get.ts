import { getPollRouterParamsSchema } from "~/schemas/polls";
import { getServerAuthSession } from "~/server/auth";
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

  const session = await getServerAuthSession(event);
  const result = await fetch.GET(
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
  if (result.error) {
    throw createError({
      statusCode: result.response.status,
      message: `${result.error.message}. ${result.error.cause}`,
    });
  }

  return result.data;
});
