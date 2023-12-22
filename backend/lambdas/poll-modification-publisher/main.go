package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/iotdataplane"
)

type DdbPoll struct {
	PollId struct {
		S string `json:"S"`
	} `'json:"PK"`
	UserId struct {
		S string `'json:"S"`
	} `'json:"GSI1PK"`
	Prompt struct {
		S string `'json:"S"`
	} `'json:"Prompt"`
	CreatedAt struct {
		S string `'json:"S"`
	} `'json:"CreatedAt"`
	Duration struct {
		N string `'json:"N"`
	} `'json:"Duration"`
	Archived struct {
		BOOL bool `'json:"BOOL"`
	} `'json:"Archived"`
}

type PollModifiedDetail struct {
	DynamoDb struct {
		NewImage DdbPoll `'json:"NewImage"`
		OldImage DdbPoll `'json:"OldImage"`
	} `'json:"dynamodb"`
}

type PollModifiedPayload struct {
	PollId    string `'json:"pollId"`
	UserId    string `'json:"userId"`
	Prompt    string `'json:"prompt"`
	CreatedAt string `'json:"createdAt"`
	Duration  int64  `'json:"duration"`
	Archived  bool   `'json:"archived"`
}

func handler(ctx context.Context, event events.CloudWatchEvent) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Printf("Error: %s\n", err)
		return
	}

	iot := iotdataplane.NewFromConfig(cfg)

	if event.Source == os.Getenv("SOURCE") && event.DetailType == os.Getenv("DETAIL_TYPE") {
		var pollModifiedDetail PollModifiedDetail
		if err := json.Unmarshal(event.Detail, &pollModifiedDetail); err != nil {
			log.Printf("Error: %s\n", err)
			return
		}
		log.Printf("Poll modified: %s\n", pollModifiedDetail.DynamoDb.NewImage.PollId.S)

		if pollModifiedDetail.DynamoDb.NewImage.Duration.N != pollModifiedDetail.DynamoDb.OldImage.Duration.N {
			log.Printf(
				"Duration changed: poll %s with %s seconds\n",
				pollModifiedDetail.DynamoDb.NewImage.PollId.S,
				pollModifiedDetail.DynamoDb.NewImage.Duration.N,
			)

			duration, err := strconv.ParseInt(pollModifiedDetail.DynamoDb.NewImage.Duration.N, 10, 64)
			if err != nil {
				log.Printf("Error: %s\n", err)
				return
			}

			payload, err := json.Marshal(PollModifiedPayload{
				PollId:    pollModifiedDetail.DynamoDb.NewImage.PollId.S,
				UserId:    pollModifiedDetail.DynamoDb.NewImage.UserId.S,
				Prompt:    pollModifiedDetail.DynamoDb.NewImage.Prompt.S,
				CreatedAt: pollModifiedDetail.DynamoDb.NewImage.CreatedAt.S,
				Duration:  duration,
				Archived:  pollModifiedDetail.DynamoDb.NewImage.Archived.BOOL,
			})
			if err != nil {
				log.Printf("Error: %s\n", err)
				return
			}

			pieces := strings.Split(pollModifiedDetail.DynamoDb.NewImage.PollId.S, "poll|")
			if len(pieces) != 2 {
				log.Printf("Error: %s\n", err)
				return
			}
			pollId := pieces[1]

			_, err = iot.Publish(ctx, &iotdataplane.PublishInput{
				Topic:       aws.String(pollId),
				ContentType: aws.String("application/json"),
				Payload:     payload,
			})
			if err != nil {
				log.Printf("Error: %s\n", err)
				return
			}

			return
		}

		return
	}

	log.Printf("Unknown event source or detail type: %s, %s\n", event.Source, event.DetailType)
	return
}

func main() {
	lambda.Start(handler)
}