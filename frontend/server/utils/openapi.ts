import createClient from "openapi-fetch";

import type { paths } from "~/types/openapi/generated";

const runtimeConfig = useRuntimeConfig();

export default createClient<paths>({
  baseUrl: runtimeConfig.api.baseUrl,
});
