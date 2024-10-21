#!/bin/bash

# Check if an argument is provided
if [ $# -eq 0 ]; then
  echo "Please provide the full image name with SHA256"
  echo "Usage: $0 <image_name>@sha256:<digest>"
  exit 1
fi

# Extract components from the input
FULL_IMAGE="$1"
REGISTRY=$(echo "$FULL_IMAGE" | cut -d'/' -f1)
PROJECT=$(echo "$FULL_IMAGE" | cut -d'/' -f2)
REPO_AND_DIGEST=$(echo "$FULL_IMAGE" | cut -d'/' -f3-)
REPO=$(echo "$REPO_AND_DIGEST" | cut -d'@' -f1)
DIGEST=$(echo "$REPO_AND_DIGEST" | cut -d':' -f2)

# Construct the API URL
API_URL="https://$REGISTRY/api/v2.0/projects/$PROJECT/repositories/$REPO/artifacts/sha256:$DIGEST/tags"

# Make the API call and extract tags
tags=$(curl -s "$API_URL" | jq -r '.[] | .name')

for t in ${tags}; do
  echo ${REGISTRY}/${PROJECT}/${REPO}:${t}
done
