# Test Documentation

## Running Tests

### Comprehensive Test Suite

Run the complete test suite:

```bash
./test-chart.sh
```

This script runs:
- ✅ Chart validation (helm lint)
- ✅ Template generation 
- ✅ Dependency updates
- ✅ Chart packaging
- ✅ Dry-run installations (default, dev, prod values)
- ✅ Namespace testing
- ✅ Values validation
- ✅ Dependency verification
- ✅ Manifest validation
- ✅ Required resources check

### Manual Testing

Individual test commands:

```bash
# Lint the chart
helm lint .

# Update dependencies
helm dependency update

# Package the chart
helm package .

# Test installation (dry-run)
helm install test-release ./shared-volume-helm-*.tgz --dry-run

# Test with custom values
helm install test-release ./shared-volume-helm-*.tgz -f values-prod.yaml --dry-run
```

## Cleanup

The test script automatically cleans up all artifacts:
- Packaged `.tgz` files
- Test directories
- Temporary files
- Backup files

All test artifacts are listed in `.gitignore` and won't be committed to the repository.

## CI/CD Integration

Tests run automatically in GitHub Actions when you push a tag. The workflow:

1. Updates dependencies
2. Runs comprehensive tests
3. Packages the chart
4. Creates GitHub release

If any test fails, the release is not created.
