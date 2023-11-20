package main

import (
	"context"
	"errors"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	nanoid "github.com/matoous/go-nanoid"
)

type InputEvent struct {
	UserId   string   `json:"userId"`
	Prompt   string   `json:"prompt"`
	Options  []string `json:"options"`
	Duration int      `json:"duration"`
}

type Poll struct {
	PollId    string   `dynamodbav:"PollId"`
	UserId    string   `dynamodbav:"UserId"`
	Prompt    string   `dynamodbav:"Prompt"`
	Options   []string `dynamodbav:"Options"`
	CreatedAt string   `dynamodbav:"CreatedAt"`
	Duration  int      `dynamodbav:"Duration"`
	Archived  bool     `dynamodbav:"Archived"`
}

type Option struct {
	OptionId  string `dynamodbav:"OptionId"`
	PollId    string `dynamodbav:"PollId"`
	Text      string `dynamodbav:"Text"`
	UpdatedAt string `dynamodbav:"UpdatedAt"`
	Votes     int    `dynamodbav:"Votes"`
}

type OutputEvent struct {
	Poll    map[string]types.AttributeValue   `json:"poll"`
	Options []map[string]types.AttributeValue `json:"options"`
}

const NanoIdAlphabet = "0123456789abcdefghijklmnopqrstuvwxyz"

func getNanoidLength() (int, error) {
	nanoIdLength, err := strconv.Atoi(os.Getenv("NANOID_LENGTH"))
	if err != nil {
		return 0, err
	}
	if !(nanoIdLength > 2 && nanoIdLength < 36) {
		return 0, errors.New("NANOID_LENGTH must be between 2 and 36")
	}
	return nanoIdLength, nil
}

func handler(ctx context.Context, event InputEvent) (OutputEvent, error) {
	currentTime := time.Now().UTC().Format(time.RFC3339)

	nanoIdLength, err := getNanoidLength()
	if err != nil {
		return OutputEvent{}, err
	}

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return OutputEvent{}, err
	}

	ddb := dynamodb.NewFromConfig(cfg)

	var transactItem types.TransactWriteItem
	var transactItems []types.TransactWriteItem

	pollId, err := nanoid.Generate(NanoIdAlphabet, nanoIdLength)
	if err != nil {
		return OutputEvent{}, err
	}

	if err != nil {
		return OutputEvent{}, err
	}
	poll, err := attributevalue.MarshalMap(Poll{
		PollId:    pollId,
		UserId:    event.UserId,
		Prompt:    event.Prompt,
		Options:   event.Options,
		CreatedAt: currentTime,
		Duration:  event.Duration,
		Archived:  false,
	})
	if err != nil {
		return OutputEvent{}, err
	}

	transactItem = types.TransactWriteItem{
		Put: &types.Put{
			TableName: aws.String(os.Getenv("POLLS_TABLE_NAME")),
			Item:      poll,
		},
	}
	transactItems = append(transactItems, transactItem)

	var options []map[string]types.AttributeValue
	for _, option := range event.Options {
		optionId, err := nanoid.Generate(NanoIdAlphabet, nanoIdLength)
		if err != nil {
			return OutputEvent{}, err
		}

		pollOption, err := attributevalue.MarshalMap(Option{
			OptionId:  optionId,
			PollId:    pollId,
			Text:      option,
			UpdatedAt: currentTime,
			Votes:     0,
		})
		if err != nil {
			return OutputEvent{}, err
		}
		options = append(options, pollOption)

		transactItem = types.TransactWriteItem{
			Put: &types.Put{
				TableName: aws.String(os.Getenv("OPTIONS_TABLE_NAME")),
				Item:      pollOption,
			},
		}
		transactItems = append(transactItems, transactItem)
	}

	_, err = ddb.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
		TransactItems: transactItems,
	})
	if err != nil {
		return OutputEvent{}, err
	}

	return OutputEvent{
		Poll:    poll,
		Options: options,
	}, nil
}

func main() {
	lambda.Start(handler)
}
