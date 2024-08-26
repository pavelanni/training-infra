#!/bin/bash

# Define the frontmatter template
FRONTMATTER=$(
    cat <<'EOF'
---
title: PLACEHOLDER_TITLE
listings-disable-line-numbers: true
listings-no-page-break: true
papersize: letter
mainfont: Inter
monofont: DejaVu Sans Mono
header-includes:
  - \usepackage{fontspec}
logo: /opt/minio/images/minio-logo.png
#logo-height: 0.4cm # default is 0.4cm
copyright: MinIO, Inc., 2024
graphics: true
---

EOF
)

# Check if running on macOS and use gsed if available, otherwise use sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v gsed &>/dev/null; then
        SED_CMD="gsed"
    else
        echo "Error: gsed is not installed. Please install it using Homebrew: brew install gnu-sed"
        exit 1
    fi
else
    SED_CMD="sed"
fi

# Update the sed commands in the script to use $SED_CMD
replace_frontmatter() {
    local file="$1"
    local title=$(grep -e "^# " "$file" | $SED_CMD 's/^# //')

    if [ -z "$title" ]; then
        title="Untitled"
    fi

    local new_frontmatter=$(echo "$FRONTMATTER" | $SED_CMD "s/PLACEHOLDER_TITLE/$title/")

    if grep -q "^---$" "$file"; then
        # Frontmatter exists, replace it
        $SED_CMD -i '1,/^---$/d' "$file"
        echo "$new_frontmatter" | cat - "$file" >temp && mv temp "$file"
    else
        # No frontmatter, add it at the beginning
        echo "$new_frontmatter" | cat - "$file" >temp && mv temp "$file"
    fi
    echo "Updated frontmatter in $file with title: $title"
}

# Find README.md files in subdirectories and process them
find . -mindepth 2 -type f -name "README.md" | while read -r file; do
    replace_frontmatter "$file"
done

echo "Frontmatter replacement complete."
