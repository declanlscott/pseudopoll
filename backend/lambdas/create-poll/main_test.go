package main

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/aws/aws-lambda-go/events"
)

func TestHandler(t *testing.T) {
	ctx := context.Background()

	requestBody, _ := json.Marshal(RequestBody{
		Prompt: "Test prompt",
		Options: []string{
			"Option 1",
			"Option 2",
			"Option 3",
		},
		Duration: 300,
	})

	mockRequest := events.APIGatewayProxyRequest{
		RequestContext: events.APIGatewayProxyRequestContext{
			Authorizer: map[string]interface{}{
				"sub": "user123",
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
