#!/bin/bash

# Function to check Terraform state in a directory
check_terraform_state() {
    local dir=$1
    local workspace=$2

    echo "Checking $dir (Workspace: $workspace)"

    # Select workspace if specified
    if [ ! -z "$workspace" ]; then
        terraform workspace select $workspace >/dev/null 2>&1
    fi

    # Check if state is empty
    if [ -z "$(terraform state list 2>/dev/null)" ]; then
        echo "  State is empty"
    else
        echo "  State contains resources:"
        terraform state list
    fi

    echo ""
}

# Check if directory parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path_to_terraform_project>"
    exit 1
fi

# Main script
main_dir="$1"

# Check if the directory exists
if [ ! -d "$main_dir" ]; then
    echo "Error: Directory '$main_dir' does not exist."
    exit 1
fi

# Iterate through subdirectories
for dir in "$main_dir"/*/; do
    if [ -d "$dir" ]; then
        pushd "$dir" >/dev/null 2>&1 || continue
        printf "Checking directory %s...\n" "$dir"

        # Check if it's a Terraform directory
        if ls *.tf >/dev/null 2>&1; then
            printf "Found Terraform... Initializing...\n"
            # Initialize Terraform
            terraform init -backend=false >/dev/null 2>&1

            # Get list of workspaces
            workspaces=$(terraform workspace list 2>/dev/null | sed 's/^[ *]//g')

            if [ -z "$workspaces" ]; then
                # If no workspaces, check default state
                printf "No workspaces found, checking default state\n"
                check_terraform_state "$dir" "default"
            else
                # Check each workspace
                printf "Found workspaces: %s\n" "$workspaces"
                for workspace in $workspaces; do
                    check_terraform_state "$dir" "$workspace"
                done
            fi
        else
            printf "No Terraform files found in %s\n" "$dir"
        fi
        popd >/dev/null 2>&1 || continue
    fi
done
