#!/bin/bash

# Function to get tags for a given image
get_tags() {
  local FULL_IMAGE="$1"
  local POD_NAME="$2"

  # Extract components from the full image
  REGISTRY=$(echo "$FULL_IMAGE" | cut -d'/' -f1)
  PROJECT=$(echo "$FULL_IMAGE" | cut -d'/' -f2)
  REPO_AND_DIGEST=$(echo "$FULL_IMAGE" | cut -d'/' -f3-)
  REPO=$(echo "$REPO_AND_DIGEST" | cut -d'@' -f1)
  DIGEST=$(echo "$REPO_AND_DIGEST" | cut -d':' -f2)

  # Construct the API URL
  API_URL="https://$REGISTRY/api/v2.0/projects/$PROJECT/repositories/$REPO/artifacts/sha256:$DIGEST/tags"

  # Make the API call and extract tags
  tags=$(curl -s "$API_URL" | jq -r '.[] | .name')

  # Print the pod name
  echo "Pod: $POD_NAME"

  # Print the full image names with tags
  for t in ${tags}; do
    echo "  ${REGISTRY}/${PROJECT}/${REPO}:${t}"
  done
  echo ""
}

# Parse command line arguments
NAMESPACE="aistor" # Default namespace
while getopts "n:" opt; do
  case $opt in
  n) NAMESPACE="$OPTARG" ;;
  *)
    echo "Usage: $0 [-n namespace]" >&2
    exit 1
    ;;
  esac
done

# Get all pods in the specified namespace
PODS=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

# Loop through each pod
for POD_NAME in $PODS; do
  # Get the image ID (SHA256) for all containers in the pod
  IMAGE_IDS=$(kubectl get pod $POD_NAME -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[*].imageID}')

  # Loop through each image ID
  for IMAGE_ID in $IMAGE_IDS; do
    # Extract the full image name with SHA256 from the image ID
    FULL_IMAGE=$(echo $IMAGE_ID | sed 's/docker-pullable:\/\///')

    # Get and print tags for this image
    get_tags "$FULL_IMAGE" "$POD_NAME"
  done
done
