export default defineEventHandler(async (event) => {
  const session = await getServerAuthSession(event);
  if (!session) {
    throw createError({
      statusCode: 401,
      message: "Unauthorized",
    });
  }

  const myPolls = await openapi.GET("/polls", {
    headers: { Authorization: `Bearer ${session.user.idToken}` },
  });

  if (myPolls.error) {
    throw createError({
      statusCode: myPolls.response.status,
      message: `${myPolls.error.message}. ${myPolls.error.cause}`,
    });
  }

  return myPolls.data;
});
