#!/bin/bash
# Import variables
source ./config.sh

# \e[36m is Cyan
echo -e "\e[36mWaking up $VM_NAME...\e[0m"
gcloud compute instances resume "$VM_NAME" --zone "$ZONE"
