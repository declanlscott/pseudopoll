import createClient from "openapi-fetch";

import type { paths } from "~/types/openapi/generated";

export default createClient<paths>({
  baseUrl: process.env.NUXT_API_BASE_URL,
});
