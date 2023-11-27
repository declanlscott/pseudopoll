package main

import (
	"context"
	"os"
	"testing"

	"github.com/aws/aws-lambda-go/events"
)

func TestHandler(t *testing.T) {
	ctx := context.Background()

	mockRequest := events.APIGatewayProxyRequest{
		PathParameters: map[string]string{
			"pollId": os.Getenv("TEST_POLL_ID"),
		},
		RequestContext: events.APIGatewayProxyRequestContext{
			Authorizer: map[string]interface{}{
				"sub": os.Getenv("TEST_USER_ID"),
			},
		},
		IsBase64Encoded: false,
	}

	res, err := handler(ctx, mockRequest)
	if err != nil {
		t.Error(err)
	}

	t.Log(res)
}
