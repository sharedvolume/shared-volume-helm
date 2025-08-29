#!/bin/bash

# SharedVolume Helm Chart Deployment Script
# This script helps deploy the shared-volume Helm chart with various configurations

set -euo pipefail

# Default values
NAMESPACE="shared-volume"
RELEASE_NAME="shared-volume"
VALUES_FILE=""
DRY_RUN=false
UPGRADE=false
WAIT=true
TIMEOUT="300s"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy the SharedVolume Helm chart

OPTIONS:
    -n, --namespace NAMESPACE     Kubernetes namespace (default: shared-volume)
    -r, --release RELEASE_NAME    Helm release name (default: shared-volume)
    -f, --values VALUES_FILE      Values file to use
    -d, --dry-run                 Perform a dry-run
    -u, --upgrade                 Upgrade existing release
    --no-wait                     Don't wait for deployment to complete
    --timeout TIMEOUT             Timeout for deployment (default: 300s)
    -h, --help                    Show this help message

EXAMPLES:
    # Deploy with default values
    $0

    # Deploy with production values
    $0 -f examples/production-values.yaml -n production

    # Upgrade existing deployment
    $0 -u -f examples/production-values.yaml

    # Dry run with custom values
    $0 -d -f examples/development-values.yaml

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -f|--values)
            VALUES_FILE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -u|--upgrade)
            UPGRADE=true
            shift
            ;;
        --no-wait)
            WAIT=false
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check Kubernetes connection
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_info "Starting SharedVolume Helm chart deployment..."
print_info "Release name: $RELEASE_NAME"
print_info "Namespace: $NAMESPACE"
print_info "Values file: ${VALUES_FILE:-"default values"}"
print_info "Dry run: $DRY_RUN"
print_info "Upgrade: $UPGRADE"

# Create namespace if it doesn't exist (only for non-dry-run)
if [[ "$DRY_RUN" == "false" ]]; then
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_info "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi
fi

# Prepare Helm command
HELM_CMD="helm"

if [[ "$UPGRADE" == "true" ]]; then
    HELM_CMD="$HELM_CMD upgrade"
else
    HELM_CMD="$HELM_CMD install"
fi

HELM_CMD="$HELM_CMD $RELEASE_NAME ."
HELM_CMD="$HELM_CMD --namespace $NAMESPACE"

if [[ "$DRY_RUN" == "true" ]]; then
    HELM_CMD="$HELM_CMD --dry-run --debug"
fi

if [[ -n "$VALUES_FILE" ]]; then
    if [[ ! -f "$VALUES_FILE" ]]; then
        print_error "Values file not found: $VALUES_FILE"
        exit 1
    fi
    HELM_CMD="$HELM_CMD --values $VALUES_FILE"
fi

if [[ "$WAIT" == "true" && "$DRY_RUN" == "false" ]]; then
    HELM_CMD="$HELM_CMD --wait --timeout $TIMEOUT"
fi

if [[ "$UPGRADE" == "false" ]]; then
    HELM_CMD="$HELM_CMD --create-namespace"
fi

# Execute Helm command
print_info "Executing: $HELM_CMD"
if eval "$HELM_CMD"; then
    if [[ "$DRY_RUN" == "false" ]]; then
        print_success "SharedVolume Helm chart deployed successfully!"
        
        # Show deployment status
        print_info "Deployment status:"
        helm status "$RELEASE_NAME" --namespace "$NAMESPACE"
        
        # Show next steps
        echo ""
        print_info "Next steps:"
        echo "1. Check the deployment status:"
        echo "   kubectl get deployments -n $NAMESPACE"
        echo ""
        echo "2. View the logs:"
        echo "   kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=shared-volume-controller"
        echo ""
        echo "3. Create a SharedVolume resource:"
        echo "   kubectl apply -f examples/shared-volume-example.yaml"
        echo ""
        echo "4. Run Helm tests:"
        echo "   helm test $RELEASE_NAME --namespace $NAMESPACE"
    else
        print_success "Dry run completed successfully!"
    fi
else
    print_error "Failed to deploy SharedVolume Helm chart"
    exit 1
fi
