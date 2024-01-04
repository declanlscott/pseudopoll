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
	PkPollId     string `dynamodbav:"PK"`
	SkPollId     string `dynamodbav:"SK"`
	Gsi1PkUserId string `dynamodbav:"GSI1PK"`
	Gsi1SkUserId string `dynamodbav:"GSI1SK"`
	Prompt       string `dynamodbav:"Prompt"`
	CreatedAt    string `dynamodbav:"CreatedAt"`
	Duration     int    `dynamodbav:"Duration"`
	IsArchived   bool   `dynamodbav:"IsArchived"`
}

type DdbOption struct {
	PkOptionId   string `dynamodbav:"PK"`
	SkOptionId   string `dynamodbav:"SK"`
	Gsi1PkPollId string `dynamodbav:"GSI1PK"`
	Gsi1SkPollId string `dynamodbav:"GSI1SK"`
	Index        int    `dynamodbav:"Index"`
	Text         string `dynamodbav:"Text"`
	UpdatedAt    string `dynamodbav:"UpdatedAt"`
	Votes        int    `dynamodbav:"Votes"`
}

type Poll struct {
	PollId     string   `json:"pollId"`
	UserId     string   `json:"userId"`
	Prompt     string   `json:"prompt"`
	Options    []Option `json:"options"`
	CreatedAt  string   `json:"createdAt"`
	Duration   int      `json:"duration"`
	IsArchived bool     `json:"isArchived"`
}

type Option struct {
	OptionId  string `json:"optionId"`
	Text      string `json:"text"`
	UpdatedAt string `json:"updatedAt"`
	Votes     int    `json:"votes"`
	IsMyVote  bool   `json:"isMyVote"`
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
	currentTime := time.Now().UTC().Format(time.RFC3339)

	nanoIdOptions, err := getNanoIdOptions()
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
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

	pollId, err := nanoid.Generate(nanoIdOptions.Alphabet, nanoIdOptions.Length)
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			},
			err,
		), nil
	}

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

	if requestBody.Duration < 1 {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusBadRequest,
				Body: formatError(
					"Bad request",
					errors.New("duration must be greater than 0"),
				),
			},
			nil,
		), nil
	}

	ddbPoll := DdbPoll{
		PkPollId:     fmt.Sprintf("poll|%s", pollId),
		SkPollId:     fmt.Sprintf("poll|%s", pollId),
		Gsi1PkUserId: fmt.Sprintf("user|%s", request.RequestContext.Authorizer["sub"].(string)),
		Gsi1SkUserId: fmt.Sprintf("user|%s", request.RequestContext.Authorizer["sub"].(string)),
		Prompt:       requestBody.Prompt,
		CreatedAt:    currentTime,
		Duration:     requestBody.Duration,
		IsArchived:   false,
	}

	item, err := attributevalue.MarshalMap(ddbPoll)
	if err != nil {
		return logAndReturn(
			events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       formatError("Internal server error", err),
			},
			err,
		), nil
	}

	var transactItem types.TransactWriteItem
	var transactItems []types.TransactWriteItem
	transactItem = types.TransactWriteItem{
		Put: &types.Put{
			TableName: aws.String(os.Getenv("SINGLE_TABLE_NAME")),
			Item:      item,
		},
	}
	transactItems = append(transactItems, transactItem)

	var ddbOption DdbOption
	var options []Option
	for index, text := range requestBody.Options {
		optionId, err := nanoid.Generate(nanoIdOptions.Alphabet, nanoIdOptions.Length)
		if err != nil {
			return logAndReturn(
				events.APIGatewayProxyResponse{
					StatusCode: http.StatusInternalServerError,
					Body:       formatError("Internal server error", err),
				},
				err,
			), nil
		}

		ddbOption = DdbOption{
			PkOptionId:   fmt.Sprintf("option|%s", optionId),
			SkOptionId:   fmt.Sprintf("option|%s", optionId),
			Gsi1PkPollId: fmt.Sprintf("poll|%s", pollId),
			Gsi1SkPollId: fmt.Sprintf("poll|%s", pollId),
			Index:        index,
			Text:         text,
			UpdatedAt:    currentTime,
			Votes:        0,
		}

		item, err := attributevalue.MarshalMap(ddbOption)
		if err != nil {
			return logAndReturn(
				events.APIGatewayProxyResponse{
					StatusCode: http.StatusInternalServerError,
					Body:       formatError("Internal server error", err),
				},
				err,
			), nil
		}
		options = append(options, Option{
			OptionId:  stripPrefix(ddbOption.PkOptionId, "option|"),
			Text:      ddbOption.Text,
			UpdatedAt: ddbOption.UpdatedAt,
			Votes:     ddbOption.Votes,
			IsMyVote:  false,
		})

		transactItem = types.TransactWriteItem{
			Put: &types.Put{
				TableName: aws.String(os.Getenv("SINGLE_TABLE_NAME")),
				Item:      item,
			},
		}
		transactItems = append(transactItems, transactItem)
	}

	_, err = ddb.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
		TransactItems: transactItems,
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

	poll, err := json.Marshal(Poll{
		PollId:     stripPrefix(ddbPoll.PkPollId, "poll|"),
		UserId:     stripPrefix(ddbPoll.Gsi1PkUserId, "user|"),
		Prompt:     ddbPoll.Prompt,
		Options:    options,
		CreatedAt:  ddbPoll.CreatedAt,
		Duration:   ddbPoll.Duration,
		IsArchived: ddbPoll.IsArchived,
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
			StatusCode: http.StatusCreated,
			Body:       string(poll),
		},
		nil,
	), nil
}

func main() {
	lambda.Start(handler)
}
