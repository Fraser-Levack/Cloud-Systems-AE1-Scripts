#!/bin/bash
# Import variables
source ./config.sh

# \e[33m is Yellow
echo -e "\e[33mSuspending $VM_NAME to save costs...\e[0m"
gcloud compute instances suspend "$VM_NAME" --zone "$ZONE"
