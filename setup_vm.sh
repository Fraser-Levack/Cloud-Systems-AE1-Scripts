#!/bin/bash

# Default values
DEFAULT_PROJECT="cloud-ae1-2775943m"
DEFAULT_VM="cloud-systems-ae1-vm"
DEFAULT_ZONE="europe-west1-c"

# Ask for user input
read -p "Enter GCloud Project ID [$DEFAULT_PROJECT]: " GCLOUD_PROJECT
GCLOUD_PROJECT=${GCLOUD_PROJECT:-$DEFAULT_PROJECT}

read -p "Enter VM Name [$DEFAULT_VM]: " VM_NAME
VM_NAME=${VM_NAME:-$DEFAULT_VM}

read -p "Enter Zone [$DEFAULT_ZONE]: " ZONE
ZONE=${ZONE:-$DEFAULT_ZONE}

# Save these to config.sh for other scripts to use
cat <<EOF > config.sh
export GCLOUD_PROJECT="$GCLOUD_PROJECT"
export VM_NAME="$VM_NAME"
export ZONE="$ZONE"
EOF

echo "Config saved to config.sh"

# Now run the setup using those variables
echo "Setting gcloud project to $GCLOUD_PROJECT..."
gcloud config set project "$GCLOUD_PROJECT"

echo "Creating VM instance..."
gcloud compute instances create "$VM_NAME" \
    --zone "$ZONE" \
    --machine-type c4-standard-2 \
    --image-family ubuntu-2404-lts-amd64 \
    --image-project ubuntu-os-cloud \
    --tags cloud-systems

echo "Resizing disk to 100GB..."
gcloud compute disks resize "$VM_NAME" --zone "$ZONE" --size 100GB --quiet

# Optional: Add that IAP firewall rule we discussed earlier!
echo "Checking for IAP firewall rule..."
gcloud compute firewall-rules create allow-ssh-ingress-from-iap \
    --direction=INGRESS --action=allow --rules=tcp:22 \
    --source-ranges=35.235.240.0/20 --quiet 2>/dev/null \
    allow-iperf \
  --allow tcp:5201

echo "Suspending VM $VM_NAME..."
gcloud compute instances suspend "$VM_NAME" --zone "$ZONE"

echo "Setup complete. VM $VM_NAME is ready and suspended."
