# Shared Volume Helm Chart

This Helm chart deploys the Shared Volume Controller along with its dependencies.

## Overview

This is an umbrella chart that includes:

- **shared-volume-controller**: The main operator for managing SharedVolume and ClusterSharedVolume resources
- **nfs-server-controller**: A dependency chart for managing NFS servers
- **cert-manager**: Certificate management for webhook TLS certificates
- **csi-driver-nfs**: CSI driver for NFS volume provisioning

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x

## Installation

### Add Required Helm Repositories

Before installing, add the required Helm repositories:

```bash
# Add jetstack repository for cert-manager
helm repo add jetstack https://charts.jetstack.io

# Add CSI driver NFS repository
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

# Update repositories
helm repo update
```

### Basic Installation

```bash
helm install shared-volume ./shared-volume-helm
```

### Installation with Custom Values

```bash
helm install shared-volume ./shared-volume-helm -f values-prod.yaml
```

### Installation in Custom Namespace

```bash
kubectl create namespace shared-volume-system
helm install shared-volume ./shared-volume-helm -n shared-volume-system
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

This chart automatically installs the following dependencies:
- **cert-manager**: For managing TLS certificates for webhooks
- **csi-driver-nfs**: For NFS CSI driver functionality
- **nfs-server-controller**: For managing NFS servers

### Manual Dependency Installation (Alternative)

If you prefer to install dependencies manually:

```bash
# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.1 \
  --set installCRDs=true

# Install CSI driver NFS
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
  --namespace kube-system \
  --version 4.11.0

# Then install shared-volume with dependencies disabled
helm install shared-volume ./shared-volume-helm \
  --set cert-manager.enabled=false \
  --set csi-driver-nfs.enabled=false
```

## License

MIT License - see [LICENSE](LICENSE) file for details.