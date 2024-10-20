package main

import (
	"context"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func Handler(ctx context.Context, request events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {

	return events.APIGatewayProxyResponse{
		Body:              "You are accessing a $default wheel",
		StatusCode:        200,
		Headers:           request.Headers,
		MultiValueHeaders: request.MultiValueHeaders,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
