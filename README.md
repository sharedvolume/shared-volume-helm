# Shared Volume Helm Chart

This Helm chart deploys the Shared Volume Controller along with its dependencies as a **complete, self-contained package**.

## Overview

This is an umbrella chart that includes:

- **shared-volume-controller**: The main operator for managing SharedVolume and ClusterSharedVolume resources
- **nfs-server-controller**: A dependency chart for managing NFS servers (bundled)
- **cert-manager**: Certificate management for webhook TLS certificates (bundled)
- **csi-driver-nfs**: CSI driver for NFS volume provisioning (bundled)

**✅ No external repositories required** - All dependencies are bundled in the package!

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x

## Installation

### Install from GitHub Repository

Install the latest stable version from GitHub:

```bash
# Install the latest release
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/archive/v0.1.0.tar.gz

# Or install a specific version
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/archive/v0.1.0.tar.gz
```

### Install from Local Repository

If you have cloned the repository locally:

```bash
# Clone the repository
git clone https://github.com/sharedvolume/shared-volume-helm.git
cd shared-volume-helm

# Install from local directory
helm install shared-volume ./
```

### Basic Installation

```bash
# Install from GitHub (recommended)
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/archive/v0.1.0.tar.gz

# Or install from local directory
helm install shared-volume ./shared-volume-helm
```

### Installation with Custom Values

```bash
# Install with production values from GitHub
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/archive/v0.1.0.tar.gz \
  -f https://raw.githubusercontent.com/sharedvolume/shared-volume-helm/v0.1.0/values-prod.yaml

# Or install from local directory with custom values
helm install shared-volume ./shared-volume-helm -f values-prod.yaml
```

### Installation in Custom Namespace

```bash
kubectl create namespace shared-volume-system
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/archive/v0.1.0.tar.gz \
  -n shared-volume-system
```

### Available Versions

You can install specific versions by changing the tag in the URL:

```bash
# Install version v0.1.0
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/archive/v0.1.0.tar.gz

# Install latest main branch (development)
helm install shared-volume \
  https://github.com/sharedvolume/shared-volume-helm/archive/main.tar.gz
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
| `global.storageClass` | Global storage class | `""` |
| `global.kubernetesClusterDomain` | Kubernetes cluster domain | `cluster.local` |

### Shared Volume Controller

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sharedVolume.enabled` | Enable shared volume controller | `true` |
| `sharedVolume.image.registry` | Image registry | `docker.io` |
| `sharedVolume.image.repository` | Image repository | `sharedvolume/shared-volume-controller` |
| `sharedVolume.image.tag` | Image tag | `latest` |
| `sharedVolume.replicaCount` | Number of replicas | `1` |
| `sharedVolume.webhook.enabled` | Enable admission webhooks | `true` |
| `sharedVolume.webhook.certManager.enabled` | Use cert-manager for certificates | `true` |
| `sharedVolume.metrics.enabled` | Enable metrics | `true` |
| `sharedVolume.networkPolicy.enabled` | Enable network policies | `false` |

### NFS Server Controller

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nfs-server.enabled` | Enable NFS server controller | `true` |
| `nfs-server.image.registry` | Image registry | `docker.io` |
| `nfs-server.image.repository` | Image repository | `sharedvolume/nfs-server-controller` |
| `nfs-server.image.tag` | Image tag | `latest` |
| `nfs-server.replicaCount` | Number of replicas | `1` |
| `nfs-server.metrics.enabled` | Enable metrics | `true` |

### cert-manager

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cert-manager.enabled` | Enable cert-manager | `true` |
| `cert-manager.installCRDs` | Install cert-manager CRDs | `true` |
| `cert-manager.webhook.replicaCount` | Webhook replicas | `1` |
| `cert-manager.cainjector.replicaCount` | CA injector replicas | `1` |

### CSI Driver NFS

| Parameter | Description | Default |
|-----------|-------------|---------|
| `csi-driver-nfs.enabled` | Enable CSI driver NFS | `true` |
| `csi-driver-nfs.controller.replicas` | Controller replicas | `1` |
| `csi-driver-nfs.feature.enableFSGroupPolicy` | Enable FSGroup policy | `true` |
| `csi-driver-nfs.feature.enableInlineVolume` | Enable inline volumes | `false` |

## Examples

### Development Environment

```yaml
# values-dev.yaml
sharedVolume:
  image:
    tag: "dev"
  webhook:
    enabled: true
  networkPolicy:
    enabled: false

nfs-server:
  image:
    tag: "dev"

cert-manager:
  enabled: true
  installCRDs: true

csi-driver-nfs:
  enabled: true
```

### Production Environment

```yaml
# values-prod.yaml
sharedVolume:
  image:
    tag: "v0.1.0"
  replicaCount: 2
  webhook:
    enabled: true
    failurePolicy: Fail
  metrics:
    serviceMonitor:
      enabled: true
  networkPolicy:
    enabled: true

nfs-server:
  image:
    tag: "v0.1.0"
  replicaCount: 2
  metrics:
    serviceMonitor:
      enabled: true

cert-manager:
  enabled: true
  installCRDs: true
  webhook:
    replicaCount: 2
  cainjector:
    replicaCount: 2
  replicaCount: 2

csi-driver-nfs:
  enabled: true
  controller:
    replicas: 2
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

Both controllers expose metrics on port 8080. Enable ServiceMonitor to scrape metrics:

```yaml
sharedVolume:
  metrics:
    serviceMonitor:
      enabled: true
      namespace: "monitoring"

nfs-server:
  metrics:
    serviceMonitor:
      enabled: true
      namespace: "monitoring"
```

### Health Checks

Health endpoints are available at:
- `/healthz` - Liveness probe
- `/readyz` - Readiness probe

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n shared-volume-system
kubectl logs -n shared-volume-system deployment/shared-volume-controller-manager
kubectl logs -n shared-volume-system deployment/shared-volume-nfs-server-controller-manager
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
kubectl get certificates -n shared-volume-system
```

## Uninstallation

```bash
helm uninstall shared-volume -n shared-volume-system
kubectl delete namespace shared-volume-system
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

MIT License - see [LICENSE](LICENSE) file for details.