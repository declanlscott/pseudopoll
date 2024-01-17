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
  const body = await readValidatedBody(event, (body) =>
    safeParse(createPollSchema(config.public), body),
  );
  if (!body.success) {
    throw createError({
      statusCode: 400,
      message: body.issues.map((issue) => issue.message).join(". "),
    });
  }

  const poll = await openapi.POST("/polls", {
    headers: { Authorization: `Bearer ${session.user.idToken}` },
    body: body.output,
  });

  if (poll.error) {
    throw createError({
      statusCode: poll.response.status,
      message: `${poll.error.message}. ${poll.error.cause}`,
    });
  }

  return poll.data;
});
