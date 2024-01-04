import type { paths } from "./generated";

export type Poll = paths["/polls/{pollId}"]["get"]["responses"]["200"]["content"]["application/json"];
