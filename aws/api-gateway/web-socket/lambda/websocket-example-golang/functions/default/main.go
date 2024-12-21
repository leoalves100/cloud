package main

import (
	"context"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func Handler(ctx context.Context, request events.APIGatewayWebsocketProxyRequest) (events.APIGatewayWebsocketProxyRequest, error) {

	return events.APIGatewayWebsocketProxyRequest{
		Body:              "You are accessing a $default wheel",
		Headers:           request.Headers,
		MultiValueHeaders: request.MultiValueHeaders,
	}, nil
}

func main() {
	lambda.Start(Handler)
}
