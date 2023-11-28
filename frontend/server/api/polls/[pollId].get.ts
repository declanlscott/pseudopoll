import { getPollRouterParamsSchema } from "~/schemas/polls";
import fetch from "~/server/fetch";

export default defineEventHandler(async (event) => {
  const routerParams = await getValidatedRouterParams(
    event,
    getPollRouterParamsSchema.safeParse
  );

  if (!routerParams.success) {
    throw createError({
      statusCode: 400,
      message: routerParams.error.message,
    });
  }

  const { pollId } = routerParams.data;

  const poll = await fetch.GET("/public/polls/{pollId}", {
    params: {
      path: { pollId },
    },
  });

  if (poll.error) {
    throw createError({
      statusCode: poll.response.status,
      message: `${poll.error.message}. ${poll.error.cause}`,
    });
  }

  return poll.data;
});
