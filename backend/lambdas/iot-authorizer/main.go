package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(
	ctx context.Context,
	request events.IoTCoreCustomAuthorizerRequest,
) (events.IoTCoreCustomAuthorizerResponse, error) {
	region := os.Getenv("AWS_REGION")
	if region == "" {
		err := errors.New("AWS_REGION environment variable not set")
		log.Printf("Error: %s", err)
		return events.IoTCoreCustomAuthorizerResponse{}, err
	}

	accountId := os.Getenv("AWS_ACCOUNT_ID")
	if accountId == "" {
		err := errors.New("AWS_ACCOUNT_ID environment variable not set")
		log.Printf("Error: %s", err)
		return events.IoTCoreCustomAuthorizerResponse{}, err
	}

	return events.IoTCoreCustomAuthorizerResponse{
		IsAuthenticated:          true,
		PrincipalID:              "user",
		DisconnectAfterInSeconds: 3600,
		RefreshAfterInSeconds:    300,
		PolicyDocuments: []*events.IAMPolicyDocument{
			{
				Version: "2012-10-17",
				Statement: []events.IAMPolicyStatement{
					{
						Effect:   "Allow",
						Action:   []string{"iot:Connect"},
						Resource: []string{fmt.Sprintf("arn:aws:iot:%s:%s:client/*", region, accountId)},
					},
					{
						Effect:   "Allow",
						Action:   []string{"iot:Subscribe"},
						Resource: []string{fmt.Sprintf("arn:aws:iot:%s:%s:topicfilter/*", region, accountId)},
					},
					{
						Effect:   "Allow",
						Action:   []string{"iot:Receive"},
						Resource: []string{fmt.Sprintf("arn:aws:iot:%s:%s:topic/*", region, accountId)},
					},
				},
			},
		},
	}, nil
}

func main() {
	lambda.Start(handler)
}
