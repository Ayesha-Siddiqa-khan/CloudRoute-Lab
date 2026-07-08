# Monitoring Stack

This folder contains raw Kubernetes manifests for Prometheus, Grafana, Node Exporter, and Fluent Bit. Fluent Bit sends Kubernetes container logs to AWS CloudWatch Logs using the EC2 worker node IAM role.

## Components

| Component | Purpose | Resource |
|-----------|---------|----------|
| Prometheus | Metrics collection and storage | Deployment |
| Grafana | Metrics visualization | Deployment |
| Node Exporter | Node-level metrics (CPU, memory, disk, network) | DaemonSet |
| Fluent Bit | Container log collection | DaemonSet |

## Prerequisites

- Kubernetes cluster running
- kubectl configured
- Terraform applied so the worker EC2 role has CloudWatch Logs permissions
- Gateway API CRDs installed separately for app traffic routing

## Install

### 1. Create Namespace

```bash
kubectl apply -f k8s/monitoring/namespace.yaml
```

### 2. Apply RBAC

```bash
kubectl apply -f k8s/monitoring/prometheus-serviceaccount.yaml
kubectl apply -f k8s/monitoring/prometheus-clusterrole.yaml
kubectl apply -f k8s/monitoring/prometheus-clusterrolebinding.yaml
```

### 3. Apply ConfigMaps

```bash
kubectl apply -f k8s/monitoring/prometheus-configmap.yaml
kubectl apply -f k8s/monitoring/grafana-datasources.yaml
kubectl apply -f k8s/monitoring/fluent-bit-configmap.yaml
```

### 4. Create Grafana Secret

```bash
cp k8s/monitoring/grafana-secret.example.yaml k8s/monitoring/grafana-secret.yaml
# edit k8s/monitoring/grafana-secret.yaml
kubectl apply -f k8s/monitoring/grafana-secret.yaml
```

### 5. Apply Fluent Bit RBAC

```bash
kubectl apply -f k8s/monitoring/fluent-bit-serviceaccount.yaml
kubectl apply -f k8s/monitoring/fluent-bit-clusterrole.yaml
kubectl apply -f k8s/monitoring/fluent-bit-clusterrolebinding.yaml
```

### 6. Apply Deployments and Services

```bash
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
kubectl apply -f k8s/monitoring/prometheus-service.yaml
kubectl apply -f k8s/monitoring/grafana-deployment.yaml
kubectl apply -f k8s/monitoring/grafana-service.yaml
```

### 7. Apply DaemonSets

```bash
kubectl apply -f k8s/monitoring/node-exporter-daemonset.yaml
kubectl apply -f k8s/monitoring/fluent-bit-daemonset.yaml
```

Avoid `kubectl apply -f k8s/monitoring/` until you have copied and edited `grafana-secret.example.yaml`; the deployment expects a real `grafana-admin` Secret.

## Verify

### Check Pods

```bash
kubectl get pods -n monitoring
```

Expected output:
```
NAME                        READY   STATUS    RESTARTS   AGE
grafana-xxxxx               1/1     Running   0          1m
node-exporter-xxxxx         1/1     Running   0          1m
prometheus-xxxxx            1/1     Running   0          1m
fluent-bit-xxxxx            1/1     Running   0          1m
```

### Check DaemonSet Pods (should run on every node)

```bash
kubectl get pods -n monitoring -o wide | grep -E "node-exporter|fluent-bit"
```

### Check Services

```bash
kubectl get svc -n monitoring
```

## Access

### Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

Open: http://localhost:9090

### Grafana

```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

Open: http://localhost:3000

Login:
- Username: `admin`
- Password: value from your local `grafana-admin` Secret

## How It Works

### Prometheus

- Scrapes metrics from Node Exporter (port 9100)
- Scrapes metrics from Kubernetes pods (if annotated)
- Stores metrics locally with 7-day retention
- Provides PromQL query interface

### Grafana

- Pre-configured with Prometheus as datasource
- Access via port-forward for lab use
- Can create dashboards for node and pod metrics

### Node Exporter (DaemonSet)

- Runs on **every node** in the cluster
- Collects CPU, memory, disk, and network metrics
- Exposes metrics on port 9100
- Prometheus scrapes from each node

### Fluent Bit (DaemonSet)

- Runs on **every node** in the cluster
- Reads container logs from `/var/log/containers/`
- Parses logs and enriches them with Kubernetes metadata
- Sends logs to CloudWatch log group `/cloudroute-lab/dev/kubernetes/containers`
- Uses the EC2 worker node IAM role; no AWS credentials are stored in YAML

Check CloudWatch delivery:

```bash
kubectl logs -n monitoring daemonset/fluent-bit
aws logs describe-log-streams --log-group-name /cloudroute-lab/dev/kubernetes/containers --region us-east-1
```

## DaemonSet Explanation

A DaemonSet ensures one copy of a pod runs on every node (or a subset). This is ideal for:

- **Node monitoring agents** (Node Exporter)
- **Log collection agents** (Fluent Bit)
- **Network plugins** (Calico, Cilium)

```bash
# Verify DaemonSet pods are on every node
kubectl get pods -n monitoring -o wide
```

## Cleanup

```bash
kubectl delete -f k8s/monitoring/
```
