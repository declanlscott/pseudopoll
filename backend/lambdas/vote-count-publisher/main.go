package main

import (
	"context"
	"encoding/json"
	"fmt"
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

type VoteCountedDetail struct {
	DynamoDb struct {
		NewImage struct {
			OptionId struct {
				S string `json:"S"`
			} `json:"PK"`
			PollId struct {
				S string `json:"S"`
			} `json:"GSI1PK"`
			Index struct {
				N string `json:"N"`
			} `json:"Index"`
			Text struct {
				S string `json:"S"`
			} `json:"Text"`
			UpdatedAt struct {
				S string `json:"S"`
			} `json:"UpdatedAt"`
			Votes struct {
				N string `json:"N"`
			} `json:"Votes"`
		} `json:"NewImage"`
	} `json:"dynamodb"`
}

type Payload struct {
	Type string      `json:"type"`
	Data interface{} `json:"data"`
}

type VoteCountedPayloadData struct {
	OptionId string `json:"optionId"`
	PollId   string `json:"pollId"`
	VotedAt  string `json:"updatedAt"`
	Votes    int64  `json:"votes"`
}

func stripPrefix(s string, prefix string) string {
	if len(s) > len(prefix) && s[0:len(prefix)] == prefix {
		return s[len(prefix):]
	}

	return s
}

func handler(ctx context.Context, event events.CloudWatchEvent) {
	log.Printf("Processing event: %s\n", event)

	if event.Source != os.Getenv("SOURCE") || event.DetailType != os.Getenv("DETAIL_TYPE") {
		log.Printf("Unknown event source or detail type: %s, %s\n", event.Source, event.DetailType)
		return
	}

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Printf("Error: %s\n", err)
		return
	}

	iot := iotdataplane.NewFromConfig(cfg)

	var voteCountedDetail VoteCountedDetail
	if err := json.Unmarshal(event.Detail, &voteCountedDetail); err != nil {
		log.Printf("Error: %s\n", err)
		return
	}
	log.Printf(
		"Vote counted: %s with %s votes\n",
		voteCountedDetail.DynamoDb.NewImage.OptionId.S,
		voteCountedDetail.DynamoDb.NewImage.Votes.N,
	)

	votes, err := strconv.ParseInt(voteCountedDetail.DynamoDb.NewImage.Votes.N, 10, 64)
	if err != nil {
		log.Printf("Error: %s\n", err)
		return
	}

	payload, err := json.Marshal(Payload{
		Type: "voteCounted",
		Data: VoteCountedPayloadData{
			OptionId: stripPrefix(voteCountedDetail.DynamoDb.NewImage.OptionId.S, "option|"),
			PollId:   stripPrefix(voteCountedDetail.DynamoDb.NewImage.PollId.S, "poll|"),
			VotedAt:  voteCountedDetail.DynamoDb.NewImage.UpdatedAt.S,
			Votes:    votes,
		},
	})
	if err != nil {
		log.Printf("Error: %s\n", err)
		return
	}

	pieces := strings.Split(voteCountedDetail.DynamoDb.NewImage.PollId.S, "poll|")
	if len(pieces) != 2 {
		log.Printf("Error: %s\n", err)
		return
	}
	pollId := pieces[1]

	_, err = iot.Publish(ctx, &iotdataplane.PublishInput{
		Topic:       aws.String(fmt.Sprintf("poll/%s", pollId)),
		ContentType: aws.String("application/json"),
		Payload:     payload,
	})
	if err != nil {
		log.Printf("Error: %s\n", err)
		return
	}

}

func main() {
	lambda.Start(handler)
}
