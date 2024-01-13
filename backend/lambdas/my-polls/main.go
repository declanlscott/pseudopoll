package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type DdbPoll struct {
	PkPollId     string `dynamodbav:"PK"`
	SkPollId     string `dynamodbav:"SK"`
	Gsi1PkUserId string `dynamodbav:"GSI1PK"`
	Gsi1SkUserId string `dynamodbav:"GSI1SK"`
	Prompt       string `dynamodbav:"Prompt"`
	CreatedAt    string `dynamodbav:"CreatedAt"`
	Duration     int    `dynamodbav:"Duration"`
	IsArchived   bool   `dynamodbav:"isArchived"`
}

type Poll struct {
	PollId     string `json:"pollId"`
	UserId     string `json:"userId"`
	Prompt     string `json:"prompt"`
	CreatedAt  string `json:"createdAt"`
	Duration   int    `json:"duration"`
	IsArchived bool   `json:"isArchived"`
}

type Error struct {
	Message string `json:"message"`
	Cause   string `json:"cause"`
}

func formatError(msg string, err error) string {
	body, _ := json.Marshal(Error{
		Message: msg,
		Cause:   err.Error(),
	})

	return string(body)
}

func logAndReturn(res events.APIGatewayProxyResponse, err error) events.APIGatewayProxyResponse {
	if err != nil {
		log.Printf("Error: %s", err)
	}

	log.Printf("Response: %v", res)

	return res
}

func stripPrefix(s string, prefix string) string {
	if len(s) > len(prefix) && s[0:len(prefix)] == prefix {
		return s[len(prefix):]
	}
	return s
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			},
			err,
		), nil
	}

	ddb := dynamodb.NewFromConfig(cfg)

	myPollsResult, err := ddb.Query(ctx, &dynamodb.QueryInput{
		TableName:              aws.String(os.Getenv("SINGLE_TABLE_NAME")),
		IndexName:              aws.String("GSI1"),
		KeyConditionExpression: aws.String("#GSI1PK = :userId AND #GSI1SK = :userId"),
		ExpressionAttributeNames: map[string]string{
			"#GSI1PK": "GSI1PK",
			"#GSI1SK": "GSI1SK",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":userId": &types.AttributeValueMemberS{
				Value: fmt.Sprintf("user|%s", request.RequestContext.Authorizer["sub"].(string)),
			},
		},
	})
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			},
			err,
		), nil
	}

	var ddbPoll DdbPoll
	var myPolls []Poll
	for _, item := range myPollsResult.Items {
		err = attributevalue.UnmarshalMap(item, &ddbPoll)
		if err != nil {
			return logAndReturn(
				events.APIGatewayProxyResponse{
					StatusCode: http.StatusInternalServerError,
					Body:       formatError("Internal server error", err),
				}, err,
			), nil
		}

		myPolls = append(myPolls, Poll{
			PollId:     stripPrefix(ddbPoll.PkPollId, "poll|"),
			UserId:     stripPrefix(ddbPoll.Gsi1PkUserId, "user|"),
			Prompt:     ddbPoll.Prompt,
			CreatedAt:  ddbPoll.CreatedAt,
			Duration:   ddbPoll.Duration,
			IsArchived: ddbPoll.IsArchived,
		})
	}

	body, err := json.Marshal(myPolls)
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			}, err,
		), nil
	}

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body:       string(body),
	}, nil
}

func main() {
	lambda.Start(handler)
}
