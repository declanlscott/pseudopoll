package main

import (
	"context"
	"testing"
)

func TestHandler(t *testing.T) {
	ctx := context.Background()

	res, err := handler(ctx, InputEvent{
		UserId: "user123",
		Prompt: "Test prompt",
		Options: []string{
			"Option 1",
			"Option 2",
			"Option 3",
		},
		Duration: 300,
	})
	if err != nil {
		t.Error(err)
	}

	t.Log(res)
}
