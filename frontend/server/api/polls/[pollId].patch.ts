import {
  updatePollDurationBodySchema,
  updatePollDurationRouterParamsSchema,
} from "~/schemas/polls";

export default defineEventHandler(async (event) => {
  const session = await getServerAuthSession(event);
  if (!session) {
    throw createError({
      statusCode: 401,
      message: "Unauthorized",
    });
  }

  const config = useRuntimeConfig();

  const routerParams = await getValidatedRouterParams(
    event,
    updatePollDurationRouterParamsSchema(config.public).safeParse,
  );
  if (!routerParams.success) {
    throw createError({
      statusCode: 400,
      message: routerParams.error.message,
    });
  }

  const body = await readValidatedBody(
    event,
    updatePollDurationBodySchema(config.public).safeParse,
  );
  if (!body.success) {
    throw createError({
      statusCode: 400,
      message: body.error.message,
    });
  }

  const result = await openapi.PATCH("/polls/{pollId}", {
    params: { path: routerParams.data },
    headers: { Authorization: `Bearer ${session.user.idToken}` },
    body: body.data,
  });
  if (result.error) {
    throw createError({
      statusCode: result.response.status,
      message: `${result.error.message}. ${result.error.cause}`,
    });
  }

  return result.data;
});
