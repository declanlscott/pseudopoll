package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/MicahParks/keyfunc/v2"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/golang-jwt/jwt/v5"
)

func getToken(request events.APIGatewayCustomAuthorizerRequest) (string, error) {
	if request.Type != "TOKEN" {
		return "", errors.New("expected 'event.Type' parameter to have value 'TOKEN'")
	}

	tokenString := request.AuthorizationToken
	if tokenString == "" {
		return "", errors.New("expected 'event.AuthorizationToken' parameter to be non-empty")
	}

	parts := strings.Split(tokenString, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return "", errors.New("invalid authorization token format")
	}

	return parts[1], nil
}

func validateToken(tokenString string) (jwt.Claims, error) {
	jwks, err := keyfunc.Get(os.Getenv("JWKS_URI"), keyfunc.Options{})

	// Parse and verify the token
	token, err := jwt.Parse(
		tokenString,
		jwks.Keyfunc,
		jwt.WithAudience(os.Getenv("AUDIENCE")),
		jwt.WithIssuer(os.Getenv("TOKEN_ISSUER")),
	)
	if err != nil {
		return nil, err
	}

	// Ensure the token is valid
	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	return token.Claims, nil
}

func logAndReturn(res events.APIGatewayCustomAuthorizerResponse, err error) events.APIGatewayCustomAuthorizerResponse {
	if err != nil {
		log.Printf("Error: %s", err)
	}

	log.Printf("Response: %s", res)

	return res
}

func handler(
	ctx context.Context,
	request events.APIGatewayCustomAuthorizerRequest,
) (events.APIGatewayCustomAuthorizerResponse, error) {
	token, err := getToken(request)
	if err != nil {
		return logAndReturn(
			events.APIGatewayCustomAuthorizerResponse{},
			errors.New("Unauthorized"),
		), err
	}

	claims, err := validateToken(token)
	if err != nil {
		return logAndReturn(
			events.APIGatewayCustomAuthorizerResponse{},
			errors.New("Unauthorized"),
		), err
	}

	return logAndReturn(
		events.APIGatewayCustomAuthorizerResponse{
			PrincipalID: fmt.Sprintf("%s", claims.(jwt.MapClaims)["sub"]),
			PolicyDocument: events.APIGatewayCustomAuthorizerPolicy{
				Version: "2012-10-17",
				Statement: []events.IAMPolicyStatement{
					{
						Effect:   "Allow",
						Resource: []string{request.MethodArn},
						Action:   []string{"execute-api:Invoke"},
					},
				},
			},
			Context: claims.(jwt.MapClaims),
		},
		nil,
	), nil
}

func main() {
	lambda.Start(handler)
}
