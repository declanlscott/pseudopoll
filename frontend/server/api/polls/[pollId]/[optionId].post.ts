import { safeParse } from "valibot";

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig();
  const routerParams = await getValidatedRouterParams(event, (params) =>
    safeParse(voteParamsSchema(config.public), params),
  );

  if (!routerParams.success) {
    throw createError({
      statusCode: 400,
      message: routerParams.issues.map((issue) => issue.message).join(". "),
    });
  }

  const session = await getServerAuthSession(event);
  const result = await openapi.POST(
    session
      ? "/polls/{pollId}/{optionId}"
      : "/public/polls/{pollId}/{optionId}",
    {
      params: {
        path: routerParams.output,
      },
      headers: session
        ? { Authorization: `Bearer ${session.user.idToken}` }
        : { "x-user-ip": getHeader(event, "cf-connecting-ip") ?? "" },
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
