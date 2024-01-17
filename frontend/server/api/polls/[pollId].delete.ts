import { safeParse } from "valibot";

export default defineEventHandler(async (event) => {
  const session = await getServerAuthSession(event);
  if (!session) {
    throw createError({
      statusCode: 401,
      message: "Unauthorized",
    });
  }

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

  const body = await readValidatedBody(event, (body) =>
    safeParse(archiveSchema, body),
  );
  if (!body.success) {
    throw createError({
      statusCode: 400,
      message: body.issues.map((issue) => issue.message).join(". "),
    });
  }

  const result = await openapi.DELETE("/polls/{pollId}", {
    params: { path: routerParams.output },
    headers: { Authorization: `Bearer ${session.user.idToken}` },
    body: body.output,
  });
  if (result.error) {
    throw createError({
      statusCode: result.response.status,
      message: `${result.error.message}. ${result.error.cause}`,
    });
  }

  return result.data;
});
