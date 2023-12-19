package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	ddbTypes "github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge"
	ebTypes "github.com/aws/aws-sdk-go-v2/service/eventbridge/types"
)

type MessageBody struct {
	OptionId         string `json:"optionId"`
	PollId           string `json:"pollId"`
	UserId           string `json:"userId"`
	SourceIp         string `json:"sourceIp"`
	RequestTimeEpoch string `json:"requestTimeEpoch"`
	RequestId        string `json:"requestId"`
}

type DdbPoll struct {
	PkPollId     string `dynamodbav:"PK"`
	SkPollId     string `dynamodbav:"SK"`
	Gsi1PkUserId string `dynamodbav:"GSI1PK"`
	Gsi1SkUserId string `dynamodbav:"GSI1SK"`
	Prompt       string `dynamodbav:"Prompt"`
	CreatedAt    string `dynamodbav:"CreatedAt"`
	Duration     int64  `dynamodbav:"Duration"`
	Archived     bool   `dynamodbav:"Archived"`
}

type DdbVote struct {
	PkVoterId string `dynamodbav:"PK"`
	SkPollId  string `dynamodbav:"SK"`
	OptionId  string `dynamodbav:"OptionId"`
	VoteId    string `dynamodbav:"VoteId"`
}

func handleError(ctx context.Context, err error, requestId string, ebClient *eventbridge.Client) {
	log.Printf("Error: %s\n", err)

	input := &eventbridge.PutEventsInput{
		Entries: []ebTypes.PutEventsRequestEntry{
			{
				EventBusName: aws.String(os.Getenv("EVENT_BUS_NAME")),
				Source:       aws.String("pseudopoll.vote-queue"),
				DetailType:   aws.String("VoteFailed"),
				Detail:       aws.String(fmt.Sprintf(`{"requestId": "%s", "error": "%s"}`, requestId, err.Error())),
			},
		},
	}

	_, err = ebClient.PutEvents(ctx, input)
	if err != nil {
		log.Printf("Error: %s\n", err)
	}
}

func handler(ctx context.Context, event events.SQSEvent) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Printf("Error: %s\n", err)
		return
	}

	ddb := dynamodb.NewFromConfig(cfg)
	ebClient := eventbridge.NewFromConfig(cfg)

	var messageBody MessageBody
	var ddbPoll DdbPoll
	var voterId string
	for _, record := range event.Records {
		if err := json.Unmarshal([]byte(record.Body), &messageBody); err != nil {
			log.Printf("Error: %s\n", err)
			continue
		}

		if messageBody.UserId != "" {
			voterId = messageBody.UserId
		} else {
			voterId = messageBody.SourceIp
		}

		requestTimeEpoch, err := strconv.ParseInt(messageBody.RequestTimeEpoch, 10, 64)
		if err != nil {
			handleError(ctx, err, messageBody.RequestId, ebClient)
			continue
		}
		requestTime := time.UnixMilli(requestTimeEpoch)

		getPoll, err := ddb.GetItem(ctx, &dynamodb.GetItemInput{
			TableName: aws.String(os.Getenv("SINGLE_TABLE_NAME")),
			Key: map[string]ddbTypes.AttributeValue{
				"PK": &ddbTypes.AttributeValueMemberS{
					Value: fmt.Sprintf("poll|%s", messageBody.PollId),
				},
				"SK": &ddbTypes.AttributeValueMemberS{
					Value: fmt.Sprintf("poll|%s", messageBody.PollId),
				},
			},
		})
		if err != nil {
			handleError(ctx, err, messageBody.RequestId, ebClient)
			continue
		}

		err = attributevalue.UnmarshalMap(getPoll.Item, &ddbPoll)
		if err != nil {
			handleError(ctx, err, messageBody.RequestId, ebClient)
			continue
		}

		if ddbPoll.Archived {
			handleError(ctx, errors.New(fmt.Sprintf("poll %s is archived", ddbPoll.PkPollId)), messageBody.RequestId, ebClient)
			continue
		}

		createdAt, err := time.Parse(time.RFC3339, ddbPoll.CreatedAt)
		if err != nil {
			handleError(ctx, err, messageBody.RequestId, ebClient)
			continue
		}

		expirationTime := createdAt.Add(time.Duration(ddbPoll.Duration) * time.Second)
		if requestTime.After(expirationTime) {
			handleError(ctx, errors.New(fmt.Sprintf("poll %s has expired", ddbPoll.PkPollId)), messageBody.RequestId, ebClient)
			continue
		}

		item, err := attributevalue.MarshalMap(DdbVote{
			PkVoterId: fmt.Sprintf("voter|%s", voterId),
			SkPollId:  fmt.Sprintf("poll|%s", messageBody.PollId),
			OptionId:  messageBody.OptionId,
			VoteId:    messageBody.RequestId,
		})
		if err != nil {
			handleError(ctx, err, messageBody.RequestId, ebClient)
			continue
		}

		_, err = ddb.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
			TransactItems: []ddbTypes.TransactWriteItem{
				{
					Put: &ddbTypes.Put{
						TableName:           aws.String(os.Getenv("SINGLE_TABLE_NAME")),
						Item:                item,
						ConditionExpression: aws.String("attribute_not_exists(#voter) AND attribute_not_exists(#poll)"),
						ExpressionAttributeNames: map[string]string{
							"#voter": "PK",
							"#poll":  "SK",
						},
					},
				},
				{
					Update: &ddbTypes.Update{
						TableName: aws.String(os.Getenv("SINGLE_TABLE_NAME")),
						Key: map[string]ddbTypes.AttributeValue{
							"PK": &ddbTypes.AttributeValueMemberS{
								Value: fmt.Sprintf("option|%s", messageBody.OptionId),
							},
							"SK": &ddbTypes.AttributeValueMemberS{
								Value: fmt.Sprintf("option|%s", messageBody.OptionId),
							},
						},
						ConditionExpression: aws.String("#poll = :poll"),
						UpdateExpression:    aws.String("SET #votes = #votes + :vote, #updatedAt = :updatedAt"),
						ExpressionAttributeNames: map[string]string{
							"#poll":      "GSI1PK",
							"#votes":     "Votes",
							"#updatedAt": "UpdatedAt",
						},
						ExpressionAttributeValues: map[string]ddbTypes.AttributeValue{
							":poll": &ddbTypes.AttributeValueMemberS{
								Value: fmt.Sprintf("poll|%s", messageBody.PollId),
							},
							":vote": &ddbTypes.AttributeValueMemberN{
								Value: "1",
							},
							":updatedAt": &ddbTypes.AttributeValueMemberS{
								Value: requestTime.Format(time.RFC3339),
							},
						},
					},
				},
			},
		})
		if err != nil {
			handleError(ctx, err, messageBody.RequestId, ebClient)
			continue
		}

		log.Printf(
			"Successfully voted for option %s on poll %s by voter %s\n",
			messageBody.OptionId,
			messageBody.PollId,
			voterId,
		)
	}
}

func main() {
	lambda.Start(handler)
}
