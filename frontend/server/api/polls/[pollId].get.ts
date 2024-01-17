import { safeParse } from "valibot";

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig();
  const routerParams = await getValidatedRouterParams(event, (params) =>
    safeParse(pollParamsSchema(config.public), params),
  );

  if (!routerParams.success) {
    throw createError({
      statusCode: 400,
      message: routerParams.issues.map((issue) => issue.message).join(". "),
    });
  }

  const session = await getServerAuthSession(event);
  const result = await openapi.GET(
    session ? "/polls/{pollId}" : "/public/polls/{pollId}",
    {
      params: {
        path: routerParams.output,
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
