#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 [-n NAMESPACE] [-c CONTAINER_NAME] POD_NAME"
  echo "Example: $0 -n default -c my-container my-pod"
  exit 1
}

# Initialize variables
NAMESPACE=""
CONTAINER_NAME=""

# Parse command-line options
while getopts ":n:c:" opt; do
  case $opt in
  n) NAMESPACE="$OPTARG" ;;
  c) CONTAINER_NAME="$OPTARG" ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    usage
    ;;
  esac
done

# Remove the options from the positional parameters
shift $((OPTIND - 1))

# Check if POD_NAME is provided
if [ $# -ne 1 ]; then
  usage
fi

POD_NAME="$1"

# Construct kubectl command
KUBECTL_CMD="kubectl get pod $POD_NAME"
if [ -n "$NAMESPACE" ]; then
  KUBECTL_CMD+=" -n $NAMESPACE"
fi
KUBECTL_CMD+=" -o jsonpath='{.status.containerStatuses[*].imageID}'"

# Add container filter if specified
if [ -n "$CONTAINER_NAME" ]; then
  KUBECTL_CMD=$(echo $KUBECTL_CMD | sed "s/containerStatuses\[*\]/containerStatuses[?(@.name=='$CONTAINER_NAME')]/" | sed "s/'//g")
fi

# Get the image ID (SHA256) from the running pod
IMAGE_ID=$(eval $KUBECTL_CMD)

if [ -z "$IMAGE_ID" ]; then
  echo "Error: Could not find image ID for pod '$POD_NAME'"
  [ -n "$NAMESPACE" ] && echo "Namespace: $NAMESPACE"
  [ -n "$CONTAINER_NAME" ] && echo "Container: $CONTAINER_NAME"
  exit 1
fi

# Extract the full image name with SHA256 from the image ID
FULL_IMAGE=$(echo $IMAGE_ID | sed 's/docker-pullable:\/\///')

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

# Print the full image names with tags
for t in ${tags}; do
  echo ${REGISTRY}/${PROJECT}/${REPO}:${t}
done
