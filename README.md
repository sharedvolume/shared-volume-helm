# Shared Volume Helm Chart

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Helm Chart](https://img.shields.io/badge/Helm-Chart-blue)](https://helm.sh/)
[![Release](https://img.shields.io/github/release/sharedvolume/shared-volume-helm.svg)](https://github.com/sharedvolume/shared-volume-helm/releases)

**Repository**: [https://github.com/sharedvolume/shared-volume-helm](https://github.com/sharedvolume/shared-volume-helm)  
**Releases**: [https://github.com/sharedvolume/shared-volume-helm/releases](https://github.com/sharedvolume/shared-volume-helm/releases)

This Helm chart deploys the Shared Volume Controller along with its dependencies.

## Overview

This chart includes:

- **shared-volume-controller**: The main operator for managing SharedVolume and ClusterSharedVolume resources
- **nfs-server-controller**: A dependency chart for managing NFS servers (bundled)

## Component Versions

This Helm chart includes the following component versions:

| Component | Version | GitHub Release |
|-----------|---------|----------------|
| shared-volume-controller | v0.1.0 | [GitHub Releases](https://github.com/sharedvolume/shared-volume-controller/releases) |
| nfs-server-controller | v0.1.0 | [GitHub Releases](https://github.com/sharedvolume/nfs-server-controller/releases) |
| nfs-server | v0.1.0-alpine-3.22.0 | [GitHub Releases](https://github.com/sharedvolume/nfs-server/releases) |
| volume-syncer | v0.1.0 | [GitHub Releases](https://github.com/sharedvolume/volume-syncer/releases) |

For the latest versions and release notes, check the individual component repositories above.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- **cert-manager**: Must be installed manually before installing this chart
- **CSI NFS driver**: Must be installed manually before installing this chart

## Installation

### Prerequisites Installation

Before installing this chart, you must install cert-manager and CSI NFS driver:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# Install CSI NFS driver
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version v4.11.0
```

### Basic Installation

```bash
# Install from GitHub releases (recommended)
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/releases/download/v0.1.0/shared-volume-0.1.0.tgz

# Or install from local directory
git clone https://github.com/sharedvolume/shared-volume-helm.git
cd shared-volume-helm
helm install shared-volume ./shared-volume
```

### Installation with Custom Configuration

```bash
# Install with custom namespace
kubectl create namespace my-namespace
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/releases/download/v0.1.0/shared-volume-0.1.0.tgz \
  -n my-namespace

# Install without NFS Server Controller
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/releases/download/v0.1.0/shared-volume-0.1.0.tgz \
  --set nfsServer.enabled=false

# Install with custom values file
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/releases/download/v0.1.0/shared-volume-0.1.0.tgz \
  -f custom-values.yaml
```

## Upgrading

### Upgrade to Latest Version

```bash
# Upgrade from GitHub
helm upgrade shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/archive/v0.1.0.tar.gz

# Or upgrade from local directory
helm upgrade shared-volume ./shared-volume-helm
```

### Upgrade with New Values

```bash
helm upgrade shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/archive/v0.1.0.tar.gz \
  -f values-prod.yaml
```

## Configuration

### Global Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global image registry | `""` |
| `global.imagePullSecrets` | Global image pull secrets | `[]` |

### Shared Volume Controller

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sharedVolume.enabled` | Enable shared volume controller | `true` |
| `sharedVolume.image.registry` | Image registry | `docker.io` |
| `sharedVolume.image.repository` | Image repository | `sharedvolume/shared-volume-controller` |
| `sharedVolume.image.tag` | Image tag | `0.1.0` |
| `sharedVolume.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `sharedVolume.replicaCount` | Number of replicas | `1` |
| `sharedVolume.namespace` | Controller namespace | `shared-volume-controller-system` |
| `sharedVolume.volumeSyncerImage` | Volume syncer image | `sharedvolume/volume-syncer:0.1.0` |
| `sharedVolume.certManager.enabled` | Enable cert-manager integration | `true` |

### NFS Server Controller

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nfsServer.enabled` | Enable NFS server controller | `true` |
| `nfsServer.image.registry` | Image registry | `docker.io` |
| `nfsServer.image.repository` | Image repository | `sharedvolume/nfs-server-controller` |
| `nfsServer.image.tag` | Image tag | `0.1.0` |
| `nfsServer.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `nfsServer.replicaCount` | Number of replicas | `1` |
| `nfsServer.namespace` | Controller namespace | `nfs-server-controller-system` |
| `nfsServer.nfsServerImage` | NFS server image | `sharedvolume/nfs-server:0.1.0-alpine-3.22.0` |

## Examples

### Development Environment

```yaml
# values-dev.yaml
sharedVolume:
  image:
    tag: "dev"
  certManager:
    enabled: true

nfsServer:
  image:
    tag: "dev"
```

### Production Environment

```yaml
# values-prod.yaml
sharedVolume:
  image:
    tag: "v0.1.0"
  replicaCount: 2
  certManager:
    enabled: true

nfsServer:
  image:
    tag: "v0.1.0"
  replicaCount: 2
```

## Usage After Installation

### Create a SharedVolume

```yaml
apiVersion: sv.sharedvolume.io/v1alpha1
kind: SharedVolume
metadata:
  name: my-shared-volume
  namespace: default
spec:
  mountPath: "/shared"
  storage:
    capacity: "10Gi"
  storageClassName: "standard"
```

### Create a Pod with Automatic Volume Mounting

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  annotations:
    sv.sharedvolume.io/mount: "my-shared-volume:/app/shared"
spec:
  containers:
  - name: app
    image: nginx
```

## Monitoring

### Prometheus Metrics

Both controllers expose metrics on port 8443:

```yaml
sharedVolume:
  metricsService:
    port: 8443

nfsServer:
  metricsService:
    port: 8443
```

### Health Checks

Health endpoints are available at:
- `/healthz` - Liveness probe
- `/readyz` - Readiness probe

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n shared-volume-controller-system
kubectl get pods -n nfs-server-controller-system
kubectl logs -n shared-volume-controller-system deployment/shared-volume-controller-controller-manager
kubectl logs -n nfs-server-controller-system deployment/nfs-server-controller-controller-manager
```

### Check CRDs

```bash
kubectl get crd | grep sharedvolume
kubectl get sharedvolumes -A
kubectl get nfsservers -A
```

### Webhook Issues

```bash
kubectl get validatingwebhookconfiguration
kubectl get mutatingwebhookconfiguration
kubectl get certificates -n shared-volume-controller-system
```

## Uninstallation

```bash
helm uninstall shared-volume -n shared-volume-controller-system
kubectl delete namespace shared-volume-controller-system
kubectl delete namespace nfs-server-controller-system
```

## Chart Development

### Lint Chart

```bash
helm lint ./shared-volume-helm
```

### Template Chart

```bash
helm template shared-volume ./shared-volume-helm
```

### Package Chart

```bash
helm package ./shared-volume-helm
```

## Dependencies

This chart is a self-contained umbrella chart that includes all dependencies bundled together:

- **cert-manager**: For managing TLS certificates for webhooks (bundled)
- **csi-driver-nfs**: For NFS CSI driver functionality (bundled)  
- **nfs-server-controller**: For managing NFS servers (bundled)

**No external Helm repositories required!** All dependencies are included in the package.

### Dependency Management

The chart automatically handles all dependency installation and configuration. When you install this chart, it will:

1. **Install cert-manager** with the correct configuration
2. **Install csi-driver-nfs** with NFS CSI driver support
3. **Install nfs-server-controller** for NFS server management
4. **Install shared-volume-controller** as the main operator

All components are configured to work together seamlessly.

## License

Apache 2.0 License - see [LICENSE](LICENSE) file for details.

---

<div align="center">

**⭐ Star this repository if it helped you!**

[![GitHub stars](https://img.shields.io/github/stars/sharedvolume/shared-volume-helm?style=social)](https://github.com/sharedvolume/shared-volume-helm/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/sharedvolume/shared-volume-helm?style=social)](https://github.com/sharedvolume/shared-volume-helm/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/sharedvolume/shared-volume-helm?style=social)](https://github.com/sharedvolume/shared-volume-helm/watchers)

[Website](https://sharedvolume.github.io) • [Helm Chart](https://github.com/sharedvolume/shared-volume-helm) • [Contributing](CONTRIBUTING.md)

</div>