package main

import (
	"context"
	"encoding/json"
	"os"
	"testing"

	"github.com/aws/aws-lambda-go/events"
)

func TestHandler(t *testing.T) {
	ctx := context.Background()

	requestBody, _ := json.Marshal(RequestBody{
		PollId:   os.Getenv("TEST_POLL_ID"),
		Archived: os.Getenv("TEST_POLL_ARCHIVED") == "true",
	})

	mockRequest := events.APIGatewayProxyRequest{
		RequestContext: events.APIGatewayProxyRequestContext{
			Authorizer: map[string]interface{}{
				"sub": os.Getenv("TEST_USER_ID"),
			},
		},
		Body: string(requestBody),
	}

	res, err := handler(ctx, mockRequest)
	if err != nil {
		t.Error(err)
	}

	t.Log(res)
}
