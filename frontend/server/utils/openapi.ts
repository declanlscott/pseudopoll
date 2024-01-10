import createClient from "openapi-fetch";

import type { paths } from "~/openapi/types/generated";

export default createClient<paths>({
  baseUrl: process.env.NUXT_API_BASE_URL,
});
