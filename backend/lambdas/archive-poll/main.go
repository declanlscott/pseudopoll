package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type RequestBody struct {
	Archived bool `json:"archived"`
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
	var requestBody RequestBody
	if err := json.Unmarshal([]byte(request.Body), &requestBody); err != nil {
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

	input := &dynamodb.UpdateItemInput{
		Key: map[string]types.AttributeValue{
			"PollId": &types.AttributeValueMemberS{
				Value: request.PathParameters["pollId"],
			},
		},
		TableName:           aws.String(os.Getenv("POLLS_TABLE_NAME")),
		ConditionExpression: aws.String("#userId = :userId AND #archived <> :archived"),
		UpdateExpression:    aws.String("SET #archived = :archived"),
		ExpressionAttributeNames: map[string]string{
			"#userId":   "UserId",
			"#archived": "Archived",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":userId": &types.AttributeValueMemberS{
				Value: request.RequestContext.Authorizer["sub"].(string),
			},
			":archived": &types.AttributeValueMemberBOOL{
				Value: requestBody.Archived,
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

	return logAndReturn(
		events.APIGatewayProxyResponse{
			StatusCode: http.StatusNoContent,
		},
		nil,
	), nil
}

func main() {
	lambda.Start(handler)
}
