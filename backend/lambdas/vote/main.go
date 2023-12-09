package main

import (
	"context"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, event events.SQSEvent) error {
	log.Printf("Event: %s\n", event)
	for index, record := range event.Records {
		log.Printf("Record %d: %s\n", index, record.Body)
	}

	return nil
}

func main() {
	lambda.Start(handler)
}
