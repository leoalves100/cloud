package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"go.uber.org/zap"
)

type DynamoRecord struct {
	Id  string `json:"id"`
	Msg string `json:"msg"`
}

func Handler(ctx context.Context, request events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	var requestBody = request.Body
	var item DynamoRecord
	tableName := os.Getenv("DYNAMODB_TABLE")

	// Config zap log
	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatalf("can't initialize zap logger: %v", err)
	}
	defer logger.Sync()

	if err := json.Unmarshal([]byte(requestBody), &item); err != nil {
		logger.Error("error converting body to JSON",
			zap.Error(err),
		)

		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       "error converting body to JSON",
		}, nil
	}

	logger.Info("request received",
		zap.Any("body", item),
	)

	// Config autentication AWS
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	dynamodbClient := dynamodb.New(sess)

	av, err := dynamodbattribute.MarshalMap(item)
	if err != nil {
		logger.Error("error marshalling item dynamodb attribute",
			zap.Error(err),
		)

		return events.APIGatewayProxyResponse{StatusCode: 500}, nil
	}

	input := &dynamodb.PutItemInput{
		Item:      av,
		TableName: aws.String(tableName),
	}

	_, err = dynamodbClient.PutItem(input)
	if err != nil {
		logger.Error("got error calling PutItem",
			zap.Error(err),
		)

		return events.APIGatewayProxyResponse{StatusCode: 500}, nil
	}

	logger.Info("item successfully inserted into table",
		zap.Any("items", item),
	)

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusCreated,
		Body:       "Created",
	}, nil
}

func main() {
	lambda.Start(Handler)
}
