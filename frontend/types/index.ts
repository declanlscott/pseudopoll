import type { components } from "~/types/openapi/generated";

export type Poll = components["schemas"]["Poll"];

type VoteCountedPayloadData = {
  optionId: Poll["options"][number]["optionId"];
  pollId: Poll["pollId"];
  updatedAt: Poll["options"][number]["updatedAt"];
  votes: Poll["options"][number]["votes"];
};
type PollModifiedPayloadData = Omit<Poll, "options">;
type PollTopicPayload =
  | { type: "voteCounted"; data: VoteCountedPayloadData }
  | { type: "pollModified"; data: PollModifiedPayloadData };

type VoteSucceededPayloadData = {
  voterId: string;
  pollId: Poll["pollId"];
  optionId: Poll["options"][number]["optionId"];
  voteId: string;
};
type VoteFailedPayloadData = {
  error: string;
  pollId: Poll["pollId"];
  optionId: Poll["options"][number]["optionId"];
};
type VoteTopicPayload =
  | { type: "voteSucceeded"; data: VoteSucceededPayloadData }
  | { type: "voteFailed"; data: VoteFailedPayloadData };

export type Payload = PollTopicPayload | VoteTopicPayload;

export type Feature = {
  title: string;
};
