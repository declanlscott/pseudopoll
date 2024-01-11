/**
 * This file was auto-generated by openapi-typescript.
 * Do not make direct changes to the file.
 */


export interface paths {
  "/polls/{pollId}/{optionId}": {
    post: {
      parameters: {
        path: {
          pollId: string;
          optionId: string;
        };
      };
      responses: {
        /** @description 202 response */
        202: {
          content: {
            "application/json": components["schemas"]["VoteAccepted"];
          };
        };
      };
    };
  };
  "/polls/{pollId}": {
    get: {
      parameters: {
        path: {
          pollId: string;
        };
      };
      responses: {
        /** @description 200 response */
        200: {
          content: {
            "application/json": components["schemas"]["Poll"];
          };
        };
        /** @description 403 response */
        403: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
        /** @description 500 response */
        500: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
      };
    };
    delete: {
      parameters: {
        path: {
          pollId: string;
        };
      };
      requestBody: {
        content: {
          "application/json": components["schemas"]["ArchivePoll"];
        };
      };
      responses: {
        /** @description 204 response */
        204: {
          content: {
          };
        };
        /** @description 400 response */
        400: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
        /** @description 500 response */
        500: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
      };
    };
    patch: {
      parameters: {
        path: {
          pollId: string;
        };
      };
      requestBody: {
        content: {
          "application/json": components["schemas"]["UpdatePollDuration"];
        };
      };
      responses: {
        /** @description 200 response */
        200: {
          content: {
            "application/json": components["schemas"]["UpdatePollDuration"];
          };
        };
        /** @description 400 response */
        400: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
        /** @description 404 response */
        404: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
        /** @description 500 response */
        500: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
      };
    };
  };
  "/polls": {
    post: {
      requestBody: {
        content: {
          "application/json": components["schemas"]["CreatePoll"];
        };
      };
      responses: {
        /** @description 201 response */
        201: {
          content: {
            "application/json": components["schemas"]["Poll"];
          };
        };
        /** @description 400 response */
        400: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
        /** @description 500 response */
        500: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
      };
    };
  };
  "/public/polls/{pollId}": {
    get: {
      parameters: {
        path: {
          pollId: string;
        };
      };
      responses: {
        /** @description 200 response */
        200: {
          content: {
            "application/json": components["schemas"]["Poll"];
          };
        };
        /** @description 401 response */
        401: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
        /** @description 403 response */
        403: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
        /** @description 500 response */
        500: {
          content: {
            "application/json": components["schemas"]["Error"];
          };
        };
      };
    };
  };
  "/public/polls/{pollId}/{optionId}": {
    post: {
      parameters: {
        path: {
          pollId: string;
          optionId: string;
        };
      };
      responses: {
        /** @description 202 response */
        202: {
          content: {
            "application/json": components["schemas"]["VoteAccepted"];
          };
        };
      };
    };
  };
}

export type webhooks = Record<string, never>;

export interface components {
  schemas: {
    /** Vote Accepted Schema */
    VoteAccepted: {
      message?: string;
      requestId: string;
    };
    /** Archive Poll Schema */
    ArchivePoll: {
      isArchived: boolean;
    };
    /** Create Poll Schema */
    CreatePoll: {
      /** @description The poll prompt */
      prompt: string;
      /** @description The options to vote on */
      options: string[];
      /** @description The duration of the poll in seconds */
      duration: number;
    };
    /** Error schema */
    Error: {
      /** @description The error message */
      message: string;
      /** @description The cause of the error */
      cause?: string;
    };
    /** Poll Schema */
    Poll: {
      pollId: string;
      userId: string;
      /** @description The poll prompt text */
      prompt: string;
      /** @description The options to vote on */
      options: {
          optionId: string;
          pollId: string;
          /** @description The option text */
          text: string;
          /** @description The time of the last vote on this option */
          updatedAt: string;
          /** @description The number of votes for this option */
          votes: number;
          /** @description Whether the current user has voted for this option */
          isMyVote: boolean;
        }[];
      /** @description The time the poll was created */
      createdAt: string;
      /** @description The duration of the poll in seconds */
      duration: number;
      /** @description Whether the poll is archived */
      isArchived: boolean;
    };
    /** Update Poll Duration Schema */
    UpdatePollDuration: {
      duration: number;
    };
  };
  responses: never;
  parameters: never;
  requestBodies: never;
  headers: never;
  pathItems: never;
}

export type $defs = Record<string, never>;

export type external = Record<string, never>;

export type operations = Record<string, never>;