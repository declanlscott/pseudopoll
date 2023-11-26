package main

import (
	"context"
	"encoding/json"
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

type RequestBody struct {
	PollId string `json:"pollId"`
}

type DdbPoll struct {
	PollId    string `dynamodbav:"PollId"`
	UserId    string `dynamodbav:"UserId"`
	Prompt    string `dynamodbav:"Prompt"`
	CreatedAt string `dynamodbav:"CreatedAt"`
	Duration  int    `dynamodbav:"Duration"`
	Archived  bool   `dynamodbav:"Archived"`
}

type DdbOption struct {
	OptionId  string `dynamodbav:"OptionId"`
	PollId    string `dynamodbav:"PollId"`
	Text      string `dynamodbav:"Text"`
	UpdatedAt string `dynamodbav:"UpdatedAt"`
	Votes     int    `dynamodbav:"Votes"`
}

type Poll struct {
	PollId    string   `json:"pollId"`
	UserId    string   `json:"userId"`
	Prompt    string   `json:"prompt"`
	Options   []Option `json:"options"`
	CreatedAt string   `json:"createdAt"`
	Duration  int      `json:"duration"`
	Archived  bool     `json:"archived"`
}

type Option struct {
	OptionId  string `json:"optionId"`
	Text      string `json:"text"`
	UpdatedAt string `json:"updatedAt"`
	Votes     int    `json:"votes"`
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

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var requestBody RequestBody
	if err := json.Unmarshal([]byte(request.Body), &requestBody); err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusBadRequest,
			Body:       formatError("Bad request", err),
		}, nil
	}

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       formatError("Internal server error", err),
		}, nil
	}

	ddb := dynamodb.NewFromConfig(cfg)

	pollResult, err := ddb.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: aws.String(os.Getenv("POLLS_TABLE_NAME")),
		Key: map[string]types.AttributeValue{
			"PollId": &types.AttributeValueMemberS{
				Value: requestBody.PollId,
			},
		},
	})
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       formatError("Internal server error", err),
		}, nil
	}

	var ddbPoll DdbPoll
	err = attributevalue.UnmarshalMap(pollResult.Item, &ddbPoll)
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       formatError("Internal server error", err),
		}, nil
	}

	if ddbPoll.Archived == true && ddbPoll.UserId != request.RequestContext.Authorizer["sub"].(string) {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusForbidden,
			Body:       formatError("Forbidden", err),
		}, nil
	}

	optionsResult, err := ddb.Query(ctx, &dynamodb.QueryInput{
		TableName:              aws.String(os.Getenv("OPTIONS_TABLE_NAME")),
		IndexName:              aws.String(os.Getenv("POLL_ID_INDEX_NAME")),
		KeyConditionExpression: aws.String("#pollId = :pollId"),
		ExpressionAttributeNames: map[string]string{
			"#pollId": "PollId",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pollId": &types.AttributeValueMemberS{
				Value: requestBody.PollId,
			},
		},
	})
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       formatError("Internal server error", err),
		}, nil
	}

	var ddbOption DdbOption
	var options []Option
	for _, item := range optionsResult.Items {
		err = attributevalue.UnmarshalMap(item, &ddbOption)
		if err != nil {
			return events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			}, nil
		}

		options = append(options, Option{
			OptionId:  ddbOption.OptionId,
			Text:      ddbOption.Text,
			UpdatedAt: ddbOption.UpdatedAt,
			Votes:     ddbOption.Votes,
		})
	}

	poll, err := json.Marshal(Poll{
		PollId:    ddbPoll.PollId,
		UserId:    ddbPoll.UserId,
		Prompt:    ddbPoll.Prompt,
		Options:   options,
		CreatedAt: ddbPoll.CreatedAt,
		Duration:  ddbPoll.Duration,
		Archived:  ddbPoll.Archived,
	})

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body:       string(poll),
	}, nil
}

func main() {
	lambda.Start(handler)
}
