package main

import (
	"context"
	"fmt"
	"os"
	"testing"

	"github.com/aws/aws-lambda-go/events"
)

func TestHandler(t *testing.T) {
	ctx := context.Background()

	res, err := handler(ctx, events.APIGatewayCustomAuthorizerRequest{
		Type:               "TOKEN",
		AuthorizationToken: fmt.Sprintf("Bearer %s", os.Getenv("AUTH0_AUTHORIZATION_TOKEN")),
	})
	if err != nil {
		t.Error(err)
	}

	fmt.Println(res)
}
