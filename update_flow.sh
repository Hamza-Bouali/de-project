#!/bin/bash

# Update the Kestra flow with the corrected network configuration
curl -X PUT \
  -H "Content-Type: application/x-yaml" \
  --data-binary @taks.yaml \
  "http://localhost:8080/api/v1/flows/de-project/update-taxi-to-postgresql"

echo "Flow updated successfully!"
