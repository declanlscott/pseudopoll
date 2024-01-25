import { safeParse } from "valibot";

export default defineEventHandler(async (event) => {
  console.log("event", event);
  console.log("headers", getHeaders(event));
  const session = await getServerAuthSession(event);
  if (!session) {
    console.log("Unauthorized", session);
    throw createError({
      statusCode: 401,
      message: "Unauthorized",
    });
  }

  const config = useRuntimeConfig();
  console.log("config", config);
  const routerParams = await getValidatedRouterParams(event, (params) =>
    safeParse(pollParamsSchema(config.public), params),
  );
  if (!routerParams.success) {
    console.log("Bad request params", routerParams);
    throw createError({
      statusCode: 400,
      message: routerParams.issues.map((issue) => issue.message).join(". "),
    });
  }
  console.log("routerParams", routerParams);

  const body = await readValidatedBody(event, (body) => {
    console.log("unknown body", body);
    const result = safeParse(archiveSchema, body);
    console.log("result", result);
    return result;
  });
  if (!body.success) {
    console.log("Bad request body", body);
    throw createError({
      statusCode: 400,
      message: body.issues.map((issue) => issue.message).join(". "),
    });
  }
  console.log("body", body);

  const result = await openapi.DELETE("/polls/{pollId}", {
    params: { path: routerParams.output },
    headers: {
      Authorization: `Bearer ${session.user.idToken}`,
    },
    body: body.output,
  });
  if (result.error) {
    console.log("API error", result.error);
    throw createError({
      statusCode: result.response.status,
      message: `${result.error.message}. ${result.error.cause}`,
    });
  }
  console.log("API result", result.data);
  return result.data;
});
