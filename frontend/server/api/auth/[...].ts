import { NuxtAuthHandler } from "#auth";

import { authOptions } from "~/server/auth";

export default NuxtAuthHandler(authOptions, useRuntimeConfig());
