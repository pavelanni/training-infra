#!/bin/bash

set -e
# Set base directories
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="${BASE_DIR}/terraform"
ANSIBLE_DIR="${BASE_DIR}/ansible"

# Function to print usage
print_usage() {
    echo "Usage: $0 [create|destroy] <deployment_name> [config_file]"
    echo "  create: Create a new Kubernetes cluster"
    echo "  destroy: Destroy an existing Kubernetes cluster"
    echo "  deployment_name: Name of the deployment (used for Terraform workspace)"
    echo "  config_file: Optional. Path to a configuration file"
}

# Check if correct number of arguments is provided
if [ "$#" -lt 2 ]; then
    print_usage
    exit 1
fi

ACTION=$1
DEPLOYMENT_NAME=$2
CONFIG_FILE=$3

SENSITIVE_VARS_FILE="${TERRAFORM_DIR}/sensitive.tfvars"

# Function to load configuration
load_config() {
    # shellcheck source=/dev/null
    if [ -n "$CONFIG_FILE" ] && [ -f "${BASE_DIR}/$CONFIG_FILE" ]; then
        source "${BASE_DIR}/$CONFIG_FILE"
    else
        # Default values
        DOMAIN_NAME="miniolabs.net"
        NODE_COUNT=4
        VOLUME_SIZE=10
        NODE_TYPE="cx22"
        HCLOUD_LOCATION="fsn1"
        ANSIBLE_USER="pavel"
    fi
}

# Function to create temporary variables file
create_vars_file() {
    cat <<EOF >"${TERRAFORM_DIR}/${DEPLOYMENT_NAME}.tfvars"
deployment_name = "$DEPLOYMENT_NAME"
domain_name = "$DOMAIN_NAME"
volume_size = $VOLUME_SIZE
node_count = $NODE_COUNT
node_type = "$NODE_TYPE"
hcloud_location = "$HCLOUD_LOCATION"
EOF
}

# Function to run Terraform
run_terraform() {
    cd "${TERRAFORM_DIR}"
    terraform init
    terraform workspace select -or-create "$DEPLOYMENT_NAME"
    if [ "$ACTION" == "create" ]; then
        terraform apply -var-file="${TERRAFORM_DIR}/${DEPLOYMENT_NAME}.tfvars" -var-file="${SENSITIVE_VARS_FILE}" -auto-approve
    elif [ "$ACTION" == "destroy" ]; then
        terraform destroy -var-file="${TERRAFORM_DIR}/${DEPLOYMENT_NAME}.tfvars" -var-file="${SENSITIVE_VARS_FILE}" -auto-approve
        # Clean up
        rm -f "${TERRAFORM_DIR}/${DEPLOYMENT_NAME}.tfvars"
    fi
    cd "${BASE_DIR}"
}

# Function to generate Ansible inventory
generate_ansible_inventory() {
    ANSIBLE_SSH_PRIVATE_KEY_FILE="${TERRAFORM_DIR}/output/${DEPLOYMENT_NAME}-admin-private-key"
    cat <<EOF >"${ANSIBLE_DIR}/inventory_${DEPLOYMENT_NAME}.ini"
[control_plane]
cp.${DEPLOYMENT_NAME}.${DOMAIN_NAME}

[nodes]
EOF

    for i in $(seq -f "%02g" 1 "$NODE_COUNT"); do
        echo "node-${i}.${DEPLOYMENT_NAME}.${DOMAIN_NAME}" >>"${ANSIBLE_DIR}/inventory_${DEPLOYMENT_NAME}.ini"
    done

    cat <<EOF >>"${ANSIBLE_DIR}/inventory_${DEPLOYMENT_NAME}.ini"

[all:vars]
ansible_user=${ANSIBLE_USER}
ansible_ssh_private_key_file=${ANSIBLE_SSH_PRIVATE_KEY_FILE}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
deployment_name=${DEPLOYMENT_NAME}
EOF
}

# Function to run Ansible
run_ansible() {
    if [ "$ACTION" == "create" ]; then
        ansible-playbook -i "${ANSIBLE_DIR}/inventory_${DEPLOYMENT_NAME}.ini" "${ANSIBLE_DIR}/k3s.yml"
    fi
}

# Function to check if all nodes are ready and stable
check_nodes_ready() {
    local max_attempts=30
    local sleep_time=20
    local stability_checks=3
    local all_ready=false

    echo "Checking node readiness and stability..."
    for attempt in $(seq 1 $max_attempts); do
        all_ready=true
        for stability_check in $(seq 1 $stability_checks); do
            while IFS= read -r host; do
                if ! ssh -o StrictHostKeyChecking=no -i "${ANSIBLE_SSH_PRIVATE_KEY_FILE}" "${ANSIBLE_USER}@${host}" 'cloud-init status | grep -q "status: done" && ! systemctl is-system-running | grep -q "stopping"'; then
                    all_ready=false
                    break 2
                fi
            done < <(grep -E "^(cp|node-[0-9]+)" "${ANSIBLE_DIR}/inventory_${DEPLOYMENT_NAME}.ini" | cut -d' ' -f1)

            if [ $stability_check -lt $stability_checks ]; then
                echo "Stability check $stability_check passed. Waiting ${sleep_time} seconds before next check..."
                sleep $sleep_time
            fi
        done

        if $all_ready; then
            echo "All nodes are ready and stable!"
            return 0
        else
            echo "Attempt $attempt: Not all nodes are ready or stable. Waiting ${sleep_time} seconds..."
            sleep $sleep_time
        fi
    done

    echo "Timeout: Not all nodes became ready and stable within $((max_attempts * sleep_time * stability_checks)) seconds."
    return 1
}

# Function to remove known_hosts entries
remove_known_hosts_entries() {
    echo "Removing known_hosts entries..."
    local known_hosts_file="${HOME}/.ssh/known_hosts"

    # Remove control plane entry
    ssh-keygen -R "cp.${DEPLOYMENT_NAME}.${DOMAIN_NAME}" -f "$known_hosts_file" 2>/dev/null

    # Remove node entries
    for i in $(seq -f "%02g" 1 "$NODE_COUNT"); do
        ssh-keygen -R "node-${i}.${DEPLOYMENT_NAME}.${DOMAIN_NAME}" -f "$known_hosts_file" 2>/dev/null
    done

    echo "Known hosts entries removed."
}

# Main execution
load_config
create_vars_file

if [ "$ACTION" == "create" ]; then
    run_terraform
    generate_ansible_inventory
    if check_nodes_ready; then
        run_ansible
    else
        echo "Failed to confirm all nodes are ready. You may need to check the nodes manually."
        exit 1
    fi
elif [ "$ACTION" == "destroy" ]; then
    run_terraform
    remove_known_hosts_entries
    rm -f "${ANSIBLE_DIR}/inventory_${DEPLOYMENT_NAME}.ini"
else
    echo "Invalid action. Use 'create' or 'destroy'."
    print_usage
    exit 1
fi
