import createClient from "openapi-fetch";

import { env } from "~/env";

import type { paths } from "~/openapi/types/generated";

export default createClient<paths>({
  baseUrl: env.API_BASE_URL,
});
