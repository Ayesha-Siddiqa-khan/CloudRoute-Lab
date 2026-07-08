#!/bin/bash
# Generate kubeconfig for GitHub Actions
# Run this on the master node after kubeadm init

set -euo pipefail

echo "=== Generating kubeconfig for GitHub Actions ==="

# Copy admin.conf to a temporary location
sudo cp /etc/kubernetes/admin.conf /tmp/kubeconfig-admin.yaml

# Replace API server endpoint with public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

sed -i "s|https://.*:6443|https://${PUBLIC_IP}:6443|g" /tmp/kubeconfig-admin.yaml

# Base64 encode the kubeconfig
KUBECONFIG_B64=$(base64 -w 0 /tmp/kubeconfig-admin.yaml)

echo ""
echo "=== Add this as KUBE_CONFIG secret in GitHub ==="
echo ""
echo "$KUBECONFIG_B64"
echo ""
echo "=== Cleanup ==="
rm /tmp/kubeconfig-admin.yaml

echo ""
echo "=== Done ==="
echo "Add the base64 output above as a GitHub Actions secret named KUBE_CONFIG"
