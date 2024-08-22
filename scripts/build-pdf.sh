#!/bin/bash
set -e
# This script uses pandoc to convert the markdown file to pdf
# We use the pandoc/extra container image for that
# The image is not avialable for ARM64 architectures so we have to run it on x86_64
# We use Podman remote for that
#
# 1. Before using this script start Podman service on the x86_64 machine
# systemctl --user enable --now podman.socket
# 2. Make it running even after the user logs out
# sudo loginctl enable-linger $USER
# 3. On the client machine (your Mac laptop) configure Podman to use Podman remote
# podman --remote system connection add pandoc --identity ~/.ssh/id_ed25519 ssh://USER@HOST/run/user/UID/podman/podman.sock
# (replace USER, UID, and HOST with your own values).
# The above assumes that you have already configured ssh access to the remote host using your private key.
#
# check the arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <markdown_file>"
    exit 1
fi
PANDOC_HOST=deep-rh
PANDOC_CONNECTION=pandoc # this comes from the podman -remote system connection command above
MD_SOURCE=$1
# Create a temp dir on the x86_64 machine
TEMP_DIR=$(ssh $PANDOC_HOST mktemp -d)
# Copy the Markdown file to /tmp on the x86_64 machine
scp "$MD_SOURCE" "$PANDOC_HOST:$TEMP_DIR/$MD_SOURCE"
bname=$(basename "$MD_SOURCE")
FILENAME="${bname%.*}"
# run the Podman command with the pandoc/extra image
podman -c "$PANDOC_CONNECTION" \
    run --rm --volume "$TEMP_DIR:/data" \
    pandoc/extra:latest-ubuntu \
    "$MD_SOURCE" -o "$FILENAME.pdf" \
    --template eisvogel --data-dir=/.pandoc --listings
# copy the pdf to the current directory
scp "$PANDOC_HOST:$TEMP_DIR/$FILENAME.pdf" .

# Remove the temp dir on the x86_64 machine
ssh $PANDOC_HOST rm -rf "$TEMP_DIR"
