#!/bin/bash
set -e
# This script uses pandoc to convert the markdown file to pdf
# We use the pandoc/extra container image for that
# check the arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <markdown_file>"
    exit 1
fi
#PANDOC_IMAGE=pandoc/extra:latest-ubuntu
PANDOC_IMAGE=quay.io/pavelanni/pandoc-minio:0.1
PANDOC_TEMPLATE=eisvogel-minio

# first argument is the markdown file
MD_SOURCE=$1
bname=$(basename "$MD_SOURCE")
FILENAME="${bname%.*}"
# run the Podman command with the pandoc/extra image
podman run --volume "$PWD:/data" \
    "$PANDOC_IMAGE" \
    "$MD_SOURCE" -o "$FILENAME.pdf" \
    --template "$PANDOC_TEMPLATE" --data-dir=/.pandoc --pdf-engine=xelatex
