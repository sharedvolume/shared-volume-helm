#!/bin/bash

# Script to update Helm chart dependencies
# This script adds required repositories and updates dependencies

set -e

echo "🔄 Adding required Helm repositories..."

# Add jetstack repository for cert-manager
echo "Adding jetstack repository..."
helm repo add jetstack https://charts.jetstack.io 2>/dev/null || echo "jetstack repository already exists"

# Add CSI driver NFS repository  
echo "Adding csi-driver-nfs repository..."
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts 2>/dev/null || echo "csi-driver-nfs repository already exists"

# Update repositories
echo "📦 Updating Helm repositories..."
helm repo update

# Update chart dependencies
echo "🔗 Updating chart dependencies..."
helm dependency update

echo "✅ Dependencies updated successfully!"
echo ""
echo "You can now install the chart with:"
echo "  helm install shared-volume . -n shared-volume-system --create-namespace"
echo ""
echo "Or use custom values:"
echo "  helm install shared-volume . -f values-prod.yaml -n shared-volume-system --create-namespace"
