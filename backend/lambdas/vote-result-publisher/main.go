package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/iotdataplane"
)

type VoteSucceededDetail struct {
	DynamoDb struct {
		NewImage struct {
			PkVoterId struct {
				S string `json:"S"`
			} `json:"PK"`
			SkPollId struct {
				S string `json:"S"`
			} `json:"SK"`
			OptionId struct {
				S string `json:"S"`
			} `json:"OptionId"`
			VoteId struct {
				S string `json:"S"`
			} `json:"VoteId"`
		} `json:"NewImage"`
	} `json:"dynamodb"`
}

type VoteFailedDetail struct {
	RequestId string `json:"requestId"`
	Error     string `json:"error"`
	PollId    string `json:"pollId"`
	OptionId  string `json:"optionId"`
}

type Payload struct {
	Type string      `json:"type"`
	Data interface{} `json:"data"`
}

type VoteSucceededPayloadData struct {
	VoterId  string `json:"voterId"`
	PollId   string `json:"pollId"`
	OptionId string `json:"optionId"`
	VoteId   string `json:"voteId"`
}

type VoteFailedPayloadData struct {
	Error    string `json:"error"`
	PollId   string `json:"pollId"`
	OptionId string `json:"optionId"`
}

func stripPrefix(s string, prefix string) string {
	if len(s) > len(prefix) && s[0:len(prefix)] == prefix {
		return s[len(prefix):]
	}

	return s
}

func handler(ctx context.Context, event events.CloudWatchEvent) {
	log.Printf("Processing event: %s\n", event)

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Printf("Error: %s\n", err)
		return
	}

	iot := iotdataplane.NewFromConfig(cfg)

	if event.Source == os.Getenv("VOTE_SUCCEEDED_SOURCE") && event.DetailType == os.Getenv("VOTE_SUCCEEDED_DETAIL_TYPE") {
		var voteSucceededDetail VoteSucceededDetail
		if err := json.Unmarshal(event.Detail, &voteSucceededDetail); err != nil {
			log.Printf("Error: %s\n", err)
			return
		}
		log.Printf("Vote succeeded: %s\n", voteSucceededDetail.DynamoDb.NewImage.VoteId.S)

		payload, err := json.Marshal(Payload{
			Type: "voteSucceeded",
			Data: VoteSucceededPayloadData{
				VoterId:  stripPrefix(voteSucceededDetail.DynamoDb.NewImage.PkVoterId.S, "voter|"),
				PollId:   stripPrefix(voteSucceededDetail.DynamoDb.NewImage.SkPollId.S, "poll|"),
				OptionId: voteSucceededDetail.DynamoDb.NewImage.OptionId.S,
				VoteId:   voteSucceededDetail.DynamoDb.NewImage.VoteId.S,
			},
		})
		if err != nil {
			log.Printf("Error: %s\n", err)
			return
		}

		_, err = iot.Publish(ctx, &iotdataplane.PublishInput{
			Topic:       aws.String(fmt.Sprintf("vote/%s", voteSucceededDetail.DynamoDb.NewImage.VoteId.S)),
			ContentType: aws.String("application/json"),
			Payload:     payload,
		})
		if err != nil {
			log.Printf("Error: %s\n", err)
			return
		}

		return
	}

	if event.Source == os.Getenv("VOTE_FAILED_SOURCE") && event.DetailType == os.Getenv("VOTE_FAILED_DETAIL_TYPE") {
		var voteFailedDetail VoteFailedDetail
		if err := json.Unmarshal(event.Detail, &voteFailedDetail); err != nil {
			log.Printf("Error: %s\n", err)
			return
		}
		log.Printf("Vote failed: %s\n", voteFailedDetail.RequestId)

		payload, err := json.Marshal(Payload{
			Type: "voteFailed",
			Data: VoteFailedPayloadData{
				Error:    voteFailedDetail.Error,
				PollId:   voteFailedDetail.PollId,
				OptionId: voteFailedDetail.OptionId,
			},
		})
		if err != nil {
			log.Printf("Error: %s\n", err)
			return
		}

		_, err = iot.Publish(ctx, &iotdataplane.PublishInput{
			Topic:       aws.String(fmt.Sprintf("vote/%s", voteFailedDetail.RequestId)),
			ContentType: aws.String("application/json"),
			Payload:     payload,
		})
		if err != nil {
			log.Printf("Error: %s\n", err)
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
