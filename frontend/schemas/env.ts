import {
  boolean,
  coerce,
  integer,
  minValue,
  number,
  object,
  string,
  transform,
  url,
} from "valibot";

export default object({
  // Server only
  NUXT_API_BASE_URL: string([url()]),
  NUXT_AUTH_JS_SECRET: string(),
  NUXT_GOOGLE_CLIENT_ID: string(),
  NUXT_GOOGLE_CLIENT_SECRET: string(),
  NUXT_WHITELIST_ENABLED: coerce(boolean(), Boolean),
  NUXT_WHITELIST_USERS: transform(string(), (csv) => csv.split(",")),

  // Server and client
  NUXT_PUBLIC_AUTHJS_BASE_URL: string([url()]),
  NUXT_PUBLIC_NANO_ID_ALPHABET: string(),
  NUXT_PUBLIC_NANO_ID_LENGTH: coerce(number([integer(), minValue(1)]), Number),
  NUXT_PUBLIC_PROMPT_MIN_LENGTH: coerce(
    number([integer(), minValue(1)]),
    Number,
  ),
  NUXT_PUBLIC_PROMPT_MAX_LENGTH: coerce(
    number([integer(), minValue(1)]),
    Number,
  ),
  NUXT_PUBLIC_OPTION_MIN_LENGTH: coerce(
    number([integer(), minValue(1)]),
    Number,
  ),
  NUXT_PUBLIC_OPTION_MAX_LENGTH: coerce(
    number([integer(), minValue(1)]),
    Number,
  ),
  NUXT_PUBLIC_MIN_OPTIONS: coerce(number([integer(), minValue(1)]), Number),
  NUXT_PUBLIC_MAX_OPTIONS: coerce(number([integer(), minValue(1)]), Number),
  NUXT_PUBLIC_MIN_DURATION: coerce(number([integer(), minValue(1)]), Number),
  NUXT_PUBLIC_MAX_DURATION: coerce(number([integer(), minValue(1)]), Number),
  NUXT_PUBLIC_IOT_ENDPOINT: string(),
  NUXT_PUBLIC_IOT_CUSTOM_AUTHORIZER_NAME: string(),
});
