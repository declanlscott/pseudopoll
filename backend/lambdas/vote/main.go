package main

import (
	"context"
	"encoding/json"
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
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
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

func handler(ctx context.Context, event events.SQSEvent) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Printf("Error: %s\n", err)
		return
	}

	ddb := dynamodb.NewFromConfig(cfg)

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
			log.Printf("Error: %s\n", err)
			continue
		}
		requestTime := time.UnixMilli(requestTimeEpoch)

		getPoll, err := ddb.GetItem(ctx, &dynamodb.GetItemInput{
			TableName: aws.String(os.Getenv("SINGLE_TABLE_NAME")),
			Key: map[string]types.AttributeValue{
				"PK": &types.AttributeValueMemberS{
					Value: fmt.Sprintf("poll|%s", messageBody.PollId),
				},
				"SK": &types.AttributeValueMemberS{
					Value: fmt.Sprintf("poll|%s", messageBody.PollId),
				},
			},
		})
		if err != nil {
			log.Printf("Error: %s\n", err)
			continue
		}

		err = attributevalue.UnmarshalMap(getPoll.Item, &ddbPoll)
		if err != nil {
			log.Printf("Error: %s\n", err)
			continue
		}

		if ddbPoll.Archived {
			log.Printf("Poll %s is archived\n", ddbPoll.PkPollId)
			continue
		}

		createdAt, err := time.Parse(time.RFC3339, ddbPoll.CreatedAt)
		if err != nil {
			log.Printf("Error: %s\n", err)
			continue
		}

		expirationTime := createdAt.Add(time.Duration(ddbPoll.Duration) * time.Second)
		if requestTime.After(expirationTime) {
			log.Printf("Poll %s has expired\n", ddbPoll.PkPollId)
			continue
		}

		item, err := attributevalue.MarshalMap(DdbVote{
			PkVoterId: fmt.Sprintf("voter|%s", voterId),
			SkPollId:  fmt.Sprintf("poll|%s", messageBody.PollId),
			OptionId:  messageBody.OptionId,
			VoteId:    messageBody.RequestId,
		})
		if err != nil {
			log.Printf("Error: %s\n", err)
			continue
		}

		_, err = ddb.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
			TransactItems: []types.TransactWriteItem{
				{
					Put: &types.Put{
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
					Update: &types.Update{
						TableName: aws.String(os.Getenv("SINGLE_TABLE_NAME")),
						Key: map[string]types.AttributeValue{
							"PK": &types.AttributeValueMemberS{
								Value: fmt.Sprintf("option|%s", messageBody.OptionId),
							},
							"SK": &types.AttributeValueMemberS{
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
						ExpressionAttributeValues: map[string]types.AttributeValue{
							":poll": &types.AttributeValueMemberS{
								Value: fmt.Sprintf("poll|%s", messageBody.PollId),
							},
							":vote": &types.AttributeValueMemberN{
								Value: "1",
							},
							":updatedAt": &types.AttributeValueMemberS{
								Value: requestTime.Format(time.RFC3339),
							},
						},
					},
				},
			},
			ReturnItemCollectionMetrics: types.ReturnItemCollectionMetricsSize,
		})
		if err != nil {
			log.Printf("Error: %s\n", err)
			continue
		}

		log.Printf(
			"Successfully voted for option %s on poll %s by voter %s\n",
			messageBody.OptionId, messageBody.PollId, voterId,
		)
	}
}

func main() {
	lambda.Start(handler)
}
