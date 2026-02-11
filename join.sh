#!/bin/bash
# Import variables
source ./config.sh

# \e[32m is Green
echo -e "\e[32mConnecting to $VM_NAME...\e[0m"
gcloud compute ssh "$VM_NAME" --zone "$ZONE"
