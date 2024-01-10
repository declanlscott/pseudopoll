import { voteRouterParamsSchema } from "~/schemas/polls";

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig();

  const routerParams = await getValidatedRouterParams(
    event,
    voteRouterParamsSchema(config.public).safeParse,
  );

  if (!routerParams.success) {
    throw createError({
      statusCode: 400,
      message: routerParams.error.message,
    });
  }

  const session = await getServerAuthSession(event);
  const result = await openapi.POST(
    session
      ? "/polls/{pollId}/{optionId}"
      : "/public/polls/{pollId}/{optionId}",
    {
      params: {
        path: routerParams.data,
      },
      headers: session
        ? { Authorization: `Bearer ${session.user.idToken}` }
        : {},
    },
  );
  if (result.error) {
    throw createError({
      statusCode: 500,
      message: "An unknown error occurred while voting on the poll.",
    });
  }

  return result.data;
});
