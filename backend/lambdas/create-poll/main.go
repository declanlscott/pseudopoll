package main

import (
	"context"
	"encoding/json"
	"errors"
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
	nanoid "github.com/matoous/go-nanoid"
)

type RequestBody struct {
	Prompt   string   `json:"prompt"`
	Options  []string `json:"options"`
	Duration int      `json:"duration"`
}

type NanoIdOptions struct {
	Alphabet string
	Length   int
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

func getNanoIdOptions() (NanoIdOptions, error) {
	alphabet := os.Getenv("NANOID_ALPHABET")
	length, err := strconv.Atoi(os.Getenv("NANOID_LENGTH"))
	if err != nil {
		return NanoIdOptions{}, err
	}
	if !(length > 2 && length < 36) {
		return NanoIdOptions{}, errors.New("NANOID_LENGTH must be between 2 and 36")
	}
	return NanoIdOptions{
		Alphabet: alphabet,
		Length:   length,
	}, nil
}

func formatError(msg string, err error) string {
	responseBody, _ := json.Marshal(Error{
		Message: msg,
		Cause:   err.Error(),
	})

	return string(responseBody)
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	currentTime := time.Now().UTC().Format(time.RFC3339)

	nanoIdOptions, err := getNanoIdOptions()
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       formatError("Internal server error", err),
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

	pollId, err := nanoid.Generate(nanoIdOptions.Alphabet, nanoIdOptions.Length)
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       formatError("Internal server error", err),
		}, nil
	}

	var requestBody RequestBody
	if err := json.Unmarshal([]byte(request.Body), &requestBody); err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusBadRequest,
			Body:       formatError("Bad request", err),
		}, nil
	}

	ddbPoll := DdbPoll{
		PollId:    pollId,
		UserId:    request.RequestContext.Authorizer["sub"].(string),
		Prompt:    requestBody.Prompt,
		CreatedAt: currentTime,
		Duration:  requestBody.Duration,
		Archived:  false,
	}

	item, err := attributevalue.MarshalMap(ddbPoll)
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       formatError("Internal server error", err),
		}, nil
	}

	var transactItem types.TransactWriteItem
	var transactItems []types.TransactWriteItem
	transactItem = types.TransactWriteItem{
		Put: &types.Put{
			TableName: aws.String(os.Getenv("POLLS_TABLE_NAME")),
			Item:      item,
		},
	}
	transactItems = append(transactItems, transactItem)

	var ddbOption DdbOption
	var options []Option
	for _, text := range requestBody.Options {
		optionId, err := nanoid.Generate(nanoIdOptions.Alphabet, nanoIdOptions.Length)
		if err != nil {
			return events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			}, nil
		}

		ddbOption = DdbOption{
			OptionId:  optionId,
			PollId:    pollId,
			Text:      text,
			UpdatedAt: currentTime,
			Votes:     0,
		}

		item, err := attributevalue.MarshalMap(ddbOption)
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

		transactItem = types.TransactWriteItem{
			Put: &types.Put{
				TableName: aws.String(os.Getenv("OPTIONS_TABLE_NAME")),
				Item:      item,
			},
		}
		transactItems = append(transactItems, transactItem)
	}

	_, err = ddb.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
		TransactItems: transactItems,
	})
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       formatError("Internal server error", err),
		}, nil
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
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       formatError("Internal server error", err),
		}, nil
	}

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusCreated,
		Body:       string(poll),
	}, nil
}

func main() {
	lambda.Start(handler)
}
