# SharedVolume Helm Chart

A professional Helm chart for deploying SharedVolume and NFS Server controllers in Kubernetes.

## Description

This Helm chart provides a complete deployment solution for:
- **NFS Server Controller**: Manages NFS server instances for persistent storage
- **Shared Volume Controller**: Manages shared volumes with multiple source types (Git, HTTP, S3, SSH)

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- cert-manager (if certificate management is enabled)

## Installation

### Add Helm Repository

```bash
helm repo add shared-volume https://your-repo-url
helm repo update
```

### Install the Chart

```bash
# Install with default values
helm install shared-volume shared-volume/shared-volume

# Install with custom values
helm install shared-volume shared-volume/shared-volume -f values.yaml

# Install in a specific namespace
helm install shared-volume shared-volume/shared-volume --namespace shared-volume --create-namespace
```

## Configuration

The following table lists the configurable parameters and their default values:

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global Docker image registry | `""` |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]` |

### NFS Server Controller Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nfsServer.enabled` | Enable NFS Server controller | `true` |
| `nfsServer.image.registry` | NFS Server controller image registry | `docker.io` |
| `nfsServer.image.repository` | NFS Server controller image repository | `sharedvolume/nfs-server-controller` |
| `nfsServer.image.tag` | NFS Server controller image tag | `0.0.20` |
| `nfsServer.image.pullPolicy` | NFS Server controller image pull policy | `IfNotPresent` |
| `nfsServer.namespace` | NFS Server controller namespace | `nfs-server-controller-system` |
| `nfsServer.replicaCount` | Number of NFS Server controller replicas | `1` |
| `nfsServer.resources.limits.cpu` | NFS Server controller CPU limit | `500m` |
| `nfsServer.resources.limits.memory` | NFS Server controller memory limit | `256Mi` |
| `nfsServer.resources.requests.cpu` | NFS Server controller CPU request | `50m` |
| `nfsServer.resources.requests.memory` | NFS Server controller memory request | `128Mi` |

### Shared Volume Controller Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sharedVolume.enabled` | Enable Shared Volume controller | `true` |
| `sharedVolume.image.registry` | Shared Volume controller image registry | `docker.io` |
| `sharedVolume.image.repository` | Shared Volume controller image repository | `sharedvolume/shared-volume-controller` |
| `sharedVolume.image.tag` | Shared Volume controller image tag | `0.0.229` |
| `sharedVolume.image.pullPolicy` | Shared Volume controller image pull policy | `IfNotPresent` |
| `sharedVolume.namespace` | Shared Volume controller namespace | `shared-volume-controller-system` |
| `sharedVolume.replicaCount` | Number of Shared Volume controller replicas | `1` |
| `sharedVolume.resources.limits.cpu` | Shared Volume controller CPU limit | `500m` |
| `sharedVolume.resources.limits.memory` | Shared Volume controller memory limit | `128Mi` |
| `sharedVolume.resources.requests.cpu` | Shared Volume controller CPU request | `10m` |
| `sharedVolume.resources.requests.memory` | Shared Volume controller memory request | `64Mi` |
| `sharedVolume.certManager.enabled` | Enable cert-manager integration | `true` |

### Common Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nameOverride` | String to partially override shared-volume.fullname | `""` |
| `fullnameOverride` | String to fully override shared-volume.fullname | `""` |
| `podAnnotations` | Annotations to add to pods | `{}` |
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `tolerations` | Tolerations for pod assignment | `[]` |
| `affinity` | Affinity for pod assignment | `{}` |

## Usage Examples

### Creating a SharedVolume

```yaml
apiVersion: sv.sharedvolume.io/v1alpha1
kind: SharedVolume
metadata:
  name: git-shared-volume
  namespace: default
spec:
  mountPath: "/shared/git-repo"
  storage:
    capacity: "10Gi"
  syncInterval: "30s"
  source:
    git:
      url: "https://github.com/example/repo.git"
      branch: "main"
```

### Creating an NFS Server

```yaml
apiVersion: sharedvolume.io/v1alpha1
kind: NfsServer
metadata:
  name: example-nfs-server
  namespace: default
spec:
  storage:
    capacity: "50Gi"
    storageClassName: "fast-ssd"
  replicas: 1
```

### Creating a ClusterSharedVolume

```yaml
apiVersion: sv.sharedvolume.io/v1alpha1
kind: ClusterSharedVolume
metadata:
  name: cluster-wide-volume
spec:
  mountPath: "/shared/cluster"
  storage:
    capacity: "100Gi"
  syncInterval: "1h"
  source:
    s3:
      bucketName: "my-bucket"
      region: "us-west-2"
      endpointUrl: "https://s3.amazonaws.com"
      accessKeyFromSecret:
        name: "s3-credentials"
        key: "access-key"
      secretKeyFromSecret:
        name: "s3-credentials"
        key: "secret-key"
```

## Architecture

The chart deploys two main components:

1. **NFS Server Controller**: Manages NFS server instances that provide network file system services
2. **Shared Volume Controller**: Manages shared volumes with various source types and automatic synchronization

Both controllers work together to provide a comprehensive shared storage solution for Kubernetes workloads.

## Custom Resource Definitions

The chart installs the following CRDs:

- `nfsservers.sharedvolume.io` - Defines NFS server instances
- `sharedvolumes.sv.sharedvolume.io` - Defines namespace-scoped shared volumes
- `clustersharedvolumes.sv.sharedvolume.io` - Defines cluster-scoped shared volumes

## Security

The chart implements security best practices:

- Non-root containers with security contexts
- RBAC with minimal required permissions
- Network policies (if enabled)
- TLS certificates for webhooks (via cert-manager)
- Pod security standards compliance

## Monitoring

Both controllers expose metrics endpoints for monitoring:

- NFS Server Controller: `:8443/metrics`
- Shared Volume Controller: `:8443/metrics`

Health check endpoints are also available:
- Liveness: `:8081/healthz`
- Readiness: `:8081/readyz`

## Upgrading

To upgrade the chart:

```bash
helm upgrade shared-volume shared-volume/shared-volume
```

## Uninstalling

To uninstall the chart:

```bash
helm uninstall shared-volume
```

**Note**: Custom Resource Definitions (CRDs) are not automatically removed. To completely clean up:

```bash
kubectl delete crd nfsservers.sharedvolume.io
kubectl delete crd sharedvolumes.sv.sharedvolume.io
kubectl delete crd clustersharedvolumes.sv.sharedvolume.io
```

## Troubleshooting

### Check Controller Status

```bash
# Check NFS Server Controller
kubectl get deployment nfs-server-controller-controller-manager -n nfs-server-controller-system

# Check Shared Volume Controller
kubectl get deployment shared-volume-controller-controller-manager -n shared-volume-controller-system
```

### View Logs

```bash
# NFS Server Controller logs
kubectl logs -n nfs-server-controller-system deployment/nfs-server-controller-controller-manager

# Shared Volume Controller logs
kubectl logs -n shared-volume-controller-system deployment/shared-volume-controller-controller-manager
```

### Check Custom Resources

```bash
# List all NFS servers
kubectl get nfsservers --all-namespaces

# List all shared volumes
kubectl get sharedvolumes --all-namespaces
kubectl get clustersharedvolumes
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- GitHub Issues: [Create an issue](https://github.com/sharedvolume/shared-volume-helm/issues)
- Documentation: [Read the docs](https://docs.sharedvolume.io)
- Community: [Join our Slack](https://slack.sharedvolume.io)
