package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type Body struct {
	Duration int `json:"duration"`
}

type DdbPoll struct {
	PollId    string `dynamodbav:"PollId"`
	UserId    string `dynamodbav:"UserId"`
	Prompt    string `dynamodbav:"Prompt"`
	CreatedAt string `dynamodbav:"CreatedAt"`
	Duration  int    `dynamodbav:"Duration"`
	Archived  bool   `dynamodbav:"Archived"`
}

type Error struct {
	Message string `json:"message"`
	Cause   string `json:"cause"`
}

func formatError(msg string, err error) string {
	responseBody, _ := json.Marshal(Error{
		Message: msg,
		Cause:   err.Error(),
	})

	return string(responseBody)
}

func logAndReturn(res events.APIGatewayProxyResponse, err error) events.APIGatewayProxyResponse {
	if err != nil {
		log.Printf("Error: %s", err)
	}

	log.Printf("Response: %v", res)

	return res
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var requestBody Body
	if err := json.Unmarshal([]byte(request.Body), &requestBody); err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusBadRequest,
				Body:       formatError("Bad request", err),
			},
			err,
		), nil
	}

	if requestBody.Duration < 1 && requestBody.Duration != -1 {
		err := errors.New("duration must be greater than 0 or -1 to close now")
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusBadRequest,
				Body:       formatError("Bad request", err),
			},
			err,
		), nil
	}

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

	getPoll, err := ddb.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: aws.String(os.Getenv("POLLS_TABLE_NAME")),
		Key: map[string]types.AttributeValue{
			"PollId": &types.AttributeValueMemberS{
				Value: request.PathParameters["pollId"],
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
	if getPoll.Item == nil {
		err = errors.New("poll not found")
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusNotFound,
				Body:       formatError("Not found", err),
			},
			err,
		), nil
	}

	var ddbPoll DdbPoll
	err = attributevalue.UnmarshalMap(getPoll.Item, &ddbPoll)
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			},
			err,
		), nil
	}

	createdAt, err := time.Parse(time.RFC3339, ddbPoll.CreatedAt)
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			},
			err,
		), nil
	}

	var duration int
	requestTime := time.UnixMilli(request.RequestContext.RequestTimeEpoch)
	newExpirationTime := createdAt.Add(time.Duration(duration) * time.Second)
	if requestBody.Duration != -1 {
		if newExpirationTime.Before(requestTime) {
			err = errors.New(
				"duration must be greater than the time since the poll was created, or -1 to close now",
			)
			return logAndReturn(
				events.APIGatewayProxyResponse{
					StatusCode: http.StatusBadRequest,
					Body:       formatError("Bad request", err),
				},
				err,
			), nil
		}

		duration = requestBody.Duration
	} else {
		if newExpirationTime.Before(requestTime) {
			err = errors.New("poll has already expired")
			return logAndReturn(
				events.APIGatewayProxyResponse{
					StatusCode: http.StatusBadRequest,
					Body:       formatError("Bad request", err),
				},
				err,
			), nil
		}

		duration = int(requestTime.Sub(createdAt).Seconds())
	}

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String(os.Getenv("POLLS_TABLE_NAME")),
		Key: map[string]types.AttributeValue{
			"PollId": &types.AttributeValueMemberS{
				Value: request.PathParameters["pollId"],
			},
		},
		ConditionExpression: aws.String("#userId = :userId"),
		UpdateExpression:    aws.String("SET #duration = :duration"),
		ExpressionAttributeNames: map[string]string{
			"#userId":   "UserId",
			"#duration": "Duration",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":userId": &types.AttributeValueMemberS{
				Value: request.RequestContext.Authorizer["sub"].(string),
			},
			":duration": &types.AttributeValueMemberN{
				Value: strconv.Itoa(duration),
			},
		},
	}

	_, err = ddb.UpdateItem(ctx, input)
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusBadRequest,
				Body:       formatError("Bad request", err),
			},
			err,
		), nil
	}

	responseBody, err := json.Marshal(Body{
		Duration: duration,
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

	return logAndReturn(
		events.APIGatewayProxyResponse{
			StatusCode: http.StatusOK,
			Body:       string(responseBody),
		},
		nil,
	), nil
}

func main() {
	lambda.Start(handler)
}
