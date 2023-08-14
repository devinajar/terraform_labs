package main

import (
	"context"
	"fmt"
	"log"

	"cloud.google.com/go/bigquery"
	"cloud.google.com/go/pubsub"
	"cloud.google.com/go/storage"
	"google.golang.org/api/option"
)

func mergeFunction(ctx context.Context, m pubsub.Message) error {
	client, err := bigquery.NewClient(ctx, var.project_id, option.WithCredentialsFile(var.service_account_key))
	if err != nil {
		log.Printf("Error creating BigQuery client: %v", err)
		return err
	}
	defer client.Close()

	mergeQuery := `
		-- Your merge SQL query here
	`

	q := client.Query(mergeQuery)
	_, err = q.Run(ctx)
	if err != nil {
		log.Printf("Error running query: %v", err)
		return err
	}

	log.Println("Merge operation completed successfully")
	return nil
}

