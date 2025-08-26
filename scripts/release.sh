#!/bin/bash
set -e

# Shared Volume Helm Chart Release Script
# This script prepares a release by bundling dependencies

echo "🚀 Preparing Shared Volume Helm Chart Release..."

# Check if version is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v0.1.0"
    exit 1
fi

VERSION=$1
echo "📦 Preparing release: $VERSION"

# Add required repositories
echo "📋 Adding Helm repositories..."
helm repo add jetstack https://charts.jetstack.io
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update

# Update dependencies
echo "⬇️  Downloading dependencies..."
helm dependency update

# Package the chart
echo "📦 Packaging chart..."
helm package .

# Check if we have uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "📝 Committing bundled dependencies..."
    git add .
    git commit -m "Bundle dependencies for $VERSION release"
else
    echo "✅ No changes to commit"
fi

# Create and push tag
echo "🏷️  Creating tag $VERSION..."
git tag $VERSION
git push origin main
git push origin $VERSION

echo "✅ Release $VERSION is ready!"
echo ""
echo "Users can now install with:"
echo "helm install shared-volume \\"
echo "  https://github.com/sharedvolume/shared-volume-helm/archive/$VERSION.tar.gz"
echo ""
echo "GitHub Release created with packaged chart at:"
echo "https://github.com/sharedvolume/shared-volume-helm/releases/tag/$VERSION"
