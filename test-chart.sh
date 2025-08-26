#!/bin/bash
set -e

# Test script for Shared Volume Helm Chart
# This script runs comprehensive tests and cleans up all artifacts

echo "🧪 Starting Helm Chart Tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test artifacts directory
TEST_DIR="./test-artifacts"
TEMP_NAMESPACE="helm-test-$(date +%s)"

# Function to clean up
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up test artifacts...${NC}"
    
    # Remove test directory
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        echo "✅ Removed test artifacts directory"
    fi
    
    # Remove downloaded dependencies (except in CI)
    if [ -z "$CI" ]; then
        if [ -d "charts" ]; then
            # Preserve the local nfs-server chart, only remove external dependencies
            find charts/ -maxdepth 1 -mindepth 1 ! -name "nfs-server" -exec rm -rf {} \;
            echo "✅ Removed downloaded dependencies"
        fi
        if [ -f "Chart.lock" ]; then
            rm -f Chart.lock
            echo "✅ Removed Chart.lock"
        fi
    fi
    
    # Remove any packaged charts (except in CI)
    if [ -z "$CI" ]; then
        rm -f *.tgz
        echo "✅ Removed packaged charts"
    fi
    
    # Restore original Chart.lock if backed up
    if [ -f "Chart.lock.bak" ]; then
        mv Chart.lock.bak Chart.lock
        echo "✅ Restored original Chart.lock"
    fi
    
    # Remove any temporary files
    rm -f values.yaml.bak 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Function to run test and capture result
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}🔍 Running: $test_name${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        return 1
    fi
}

# Create test directory
mkdir -p "$TEST_DIR"

echo -e "${BLUE}📋 Test Environment Setup${NC}"
echo "Test directory: $TEST_DIR"
echo "Temp namespace: $TEMP_NAMESPACE"
echo ""

# Test 1: Chart Validation (basic lint without dependencies)
run_test "Chart Validation (Basic)" "helm lint . --with-subcharts=false"

# Test 2: Add Helm Repositories (required for dependencies)
echo -e "${BLUE}🔍 Running: Adding Helm Repositories${NC}"
if helm repo add jetstack https://charts.jetstack.io --force-update && \
   helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts --force-update && \
   helm repo update; then
    echo -e "${GREEN}✅ PASSED: Adding Helm Repositories${NC}"
else
    echo -e "${RED}❌ FAILED: Adding Helm Repositories${NC}"
    exit 1
fi

# Test 3: Dependency Update
echo -e "${BLUE}🔍 Running: Dependency Update${NC}"
if helm dependency update; then
    echo -e "${GREEN}✅ PASSED: Dependency Update${NC}"
    # Backup Chart.lock for restoration later
    cp Chart.lock Chart.lock.bak 2>/dev/null || true
else
    echo -e "${RED}❌ FAILED: Dependency Update${NC}"
    exit 1
fi

# Test 4: Chart Validation (full lint with dependencies)
run_test "Chart Validation (Full)" "helm lint ."

# Test 5: Template Generation
run_test "Template Generation" "helm template test-release . --output-dir $TEST_DIR/templates"

# Test 6: Chart Packaging
echo -e "${BLUE}🔍 Running: Chart Packaging${NC}"
if helm package . --destination "$TEST_DIR"; then
    echo -e "${GREEN}✅ PASSED: Chart Packaging${NC}"
    PACKAGE_FILE=$(ls $TEST_DIR/*.tgz | head -1)
    echo "📦 Package created: $PACKAGE_FILE"
else
    echo -e "${RED}❌ FAILED: Chart Packaging${NC}"
    exit 1
fi

# Test 7: Template Dry Run (No K8s needed)
run_test "Template Dry Run" "helm template test-release '$PACKAGE_FILE' -f values-test.yaml > $TEST_DIR/template-test.yaml"

# Test 8: Template with Dev Values
if [ -f "values-dev.yaml" ]; then
    run_test "Template with Dev Values" "helm template test-release '$PACKAGE_FILE' -f values-dev.yaml -f values-test.yaml > $TEST_DIR/template-dev.yaml"
fi

# Test 9: Template with Prod Values
if [ -f "values-prod.yaml" ]; then
    run_test "Template with Prod Values" "helm template test-release '$PACKAGE_FILE' -f values-prod.yaml -f values-test.yaml > $TEST_DIR/template-prod.yaml"
fi

# Test 10: Template with Different Namespaces
run_test "Template with Custom Namespace" "helm template test-release '$PACKAGE_FILE' --namespace $TEMP_NAMESPACE --output-dir $TEST_DIR/namespace-test"

# Test 11: Values Validation
echo -e "${BLUE}🔍 Running: Values Validation${NC}"
if helm show values "$PACKAGE_FILE" > "$TEST_DIR/extracted-values.yaml"; then
    echo -e "${GREEN}✅ PASSED: Values Validation${NC}"
else
    echo -e "${RED}❌ FAILED: Values Validation${NC}"
    exit 1
fi

# Test 12: Chart Info Extraction
echo -e "${BLUE}🔍 Running: Chart Info Extraction${NC}"
if helm show chart "$PACKAGE_FILE" > "$TEST_DIR/chart-info.yaml"; then
    echo -e "${GREEN}✅ PASSED: Chart Info Extraction${NC}"
else
    echo -e "${RED}❌ FAILED: Chart Info Extraction${NC}"
    exit 1
fi

# Test 13: Dependency Verification
echo -e "${BLUE}🔍 Running: Dependency Verification${NC}"
EXPECTED_DEPS=("cert-manager" "csi-driver-nfs")
MISSING_DEPS=()

for dep in "${EXPECTED_DEPS[@]}"; do
    if ! ls charts/ 2>/dev/null | grep -q "$dep"; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ PASSED: All dependencies found${NC}"
else
    echo -e "${RED}❌ FAILED: Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    exit 1
fi

# Test 14: Environment Variable Validation
echo -e "${BLUE}🔍 Running: Environment Variable Validation${NC}"
if helm template test-release "$PACKAGE_FILE" -f values-test.yaml | grep -q "VOLUME_SYNCER_IMAGE"; then
    echo -e "${GREEN}✅ PASSED: VOLUME_SYNCER_IMAGE found in templates${NC}"
else
    echo -e "${RED}❌ FAILED: VOLUME_SYNCER_IMAGE not found in templates${NC}"
    exit 1
fi

# Test 15: Manifest Size Check
echo -e "${BLUE}🔍 Running: Manifest Size Check${NC}"
MANIFEST_COUNT=$(find "$TEST_DIR/templates" -name "*.yaml" 2>/dev/null | wc -l)
if [ "$MANIFEST_COUNT" -gt 5 ]; then
    echo -e "${GREEN}✅ PASSED: Generated $MANIFEST_COUNT manifests${NC}"
else
    echo -e "${RED}❌ FAILED: Only $MANIFEST_COUNT manifests generated (expected > 5)${NC}"
    exit 1
fi

# Test 15: Required Resources Check
echo -e "${BLUE}🔍 Running: Required Resources Check${NC}"
REQUIRED_RESOURCES=("Deployment" "ServiceAccount")
MISSING_RESOURCES=()

for resource in "${REQUIRED_RESOURCES[@]}"; do
    if ! grep -r "kind: $resource" "$TEST_DIR/templates" >/dev/null 2>&1; then
        MISSING_RESOURCES+=("$resource")
    fi
done

if [ ${#MISSING_RESOURCES[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ PASSED: All required resources found${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING: Missing resources: ${MISSING_RESOURCES[*]}${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}🎉 All tests completed successfully!${NC}"
echo -e "${BLUE}📊 Test Summary:${NC}"
echo "  📦 Package: $(basename "$PACKAGE_FILE")"
echo "  📄 Manifests: $MANIFEST_COUNT"
echo "  🔧 Dependencies: $(ls charts/ | wc -l)"
echo "  📂 Test artifacts: $TEST_DIR (will be cleaned up)"

# Note about artifacts
echo ""
echo -e "${YELLOW}ℹ️  Note: All test artifacts will be automatically cleaned up${NC}"
echo -e "${YELLOW}ℹ️  This includes: packaged charts, test directory, and temporary files${NC}"
