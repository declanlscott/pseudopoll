import { createPollBodySchema } from "~/schemas/polls";
import { getServerAuthSession } from "~/server/auth";
import fetch from "~/server/fetch";

export default defineEventHandler(async (event) => {
  const session = await getServerAuthSession(event);
  if (!session) {
    throw createError({
      statusCode: 401,
      message: "Unauthorized",
    });
  }

  const config = useRuntimeConfig();
  const body = await readValidatedBody(
    event,
    createPollBodySchema(config.public).safeParse,
  );
  if (!body.success) {
    throw createError({
      statusCode: 400,
      message: body.error.message,
    });
  }

  const poll = await fetch.POST("/polls", {
    headers: { Authorization: `Bearer ${session.user.idToken}` },
    body: body.data,
  });

  if (poll.error) {
    throw createError({
      statusCode: poll.response.status,
      message: `${poll.error.message}. ${poll.error.cause}`,
    });
  }

  return poll.data;
});
