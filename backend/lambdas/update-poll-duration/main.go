package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
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
	Value int `json:"value"`
}

type DdbPoll struct {
	PkPollId     string `dynamodbav:"PK"`
	SkPollId     string `dynamodbav:"SK"`
	Gsi1PkUserId string `dynamodbav:"GSI1PK"`
	Gsi1SkUserId string `dynamodbav:"GSI1SK"`
	Prompt       string `dynamodbav:"Prompt"`
	CreatedAt    string `dynamodbav:"CreatedAt"`
	Duration     int    `dynamodbav:"Duration"`
	IsArchived   bool   `dynamodbav:"IsArchived"`
}

type Error struct {
	Message string `json:"message"`
	Cause   string `json:"cause"`
}

const (
	RFC3339Milli = "2006-01-02T15:04:05.999Z07:00"
)

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

	if requestBody.Value < 1 && requestBody.Value != -1 {
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
		TableName: aws.String(os.Getenv("SINGLE_TABLE_NAME")),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{
				Value: fmt.Sprintf("poll|%s", request.PathParameters["pollId"]),
			},
			"SK": &types.AttributeValueMemberS{
				Value: fmt.Sprintf("poll|%s", request.PathParameters["pollId"]),
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

	createdAt, err := time.Parse(RFC3339Milli, ddbPoll.CreatedAt)
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			},
			err,
		), nil
	}

	requestTime := time.UnixMilli(request.RequestContext.RequestTimeEpoch)
	var newExpirationTime time.Time
	var duration int
	if requestBody.Value != -1 {
		newExpirationTime = createdAt.Add(time.Duration(requestBody.Value) * time.Second)

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
	} else {
		if createdAt.Add(time.Duration(ddbPoll.Duration) * time.Second).Before(requestTime) {
			err = errors.New("poll has already expired")
			return logAndReturn(
				events.APIGatewayProxyResponse{
					StatusCode: http.StatusBadRequest,
					Body:       formatError("Bad request", err),
				},
				err,
			), nil
		}

		newExpirationTime = requestTime

	}
	duration = int(newExpirationTime.Sub(createdAt).Seconds())

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String(os.Getenv("SINGLE_TABLE_NAME")),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{
				Value: fmt.Sprintf("poll|%s", request.PathParameters["pollId"]),
			},
			"SK": &types.AttributeValueMemberS{
				Value: fmt.Sprintf("poll|%s", request.PathParameters["pollId"]),
			},
		},
		ConditionExpression: aws.String("#userPk = :user AND #userSk = :user"),
		UpdateExpression:    aws.String("SET #duration = :duration"),
		ExpressionAttributeNames: map[string]string{
			"#userPk":   "GSI1PK",
			"#userSk":   "GSI1SK",
			"#duration": "Duration",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":user": &types.AttributeValueMemberS{
				Value: fmt.Sprintf("user|%s", request.RequestContext.Authorizer["sub"].(string)),
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
		Value: duration,
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
