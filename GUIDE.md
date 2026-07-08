# CloudRoute Lab — Kubernetes Integration Guide

This guide explains how to extend the CloudRoute Lab app with real Kubernetes resources. Follow each section when you are ready to move from local development to a Kubernetes cluster.

---

## Prerequisites

- A running Kubernetes cluster (Minikube, kind, cloud-managed, or self-hosted)
- `kubectl` configured and connected to the cluster
- `helm` (optional, for chart-based installs)

---

## 1. ClusterIP

**What:** Internal-only service for pod-to-pod communication.

**When to add:** First, when your app has multiple microservices that need to talk to each other.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: cloudroute-backend
spec:
  type: ClusterIP
  selector:
    app: cloudroute-backend
  ports:
    - port: 8000
      targetPort: 8000
```

**Steps:**
1. Deploy the backend as a Deployment (see Workloads section).
2. Create a ClusterIP Service pointing to the backend pods.
3. Update the frontend to call `http://cloudroute-backend:8000` from within the cluster.

---

## 2. NodePort

**What:** Exposes a service on a static port on each node.

**When to add:** For quick external access during development or testing.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: cloudroute-backend-nodeport
spec:
  type: NodePort
  selector:
    app: cloudroute-backend
  ports:
    - port: 8000
      targetPort: 8000
      nodePort: 30080
```

**Steps:**
1. Create a NodePort service alongside the ClusterIP service.
2. Access the backend at `http://<node-ip>:30080`.
3. Use this for local testing with Minikube or kind.

---

## 3. LoadBalancer

**What:** Provisions an external load balancer (cloud provider specific).

**When to add:** For production-like external traffic routing.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: cloudroute-backend-lb
spec:
  type: LoadBalancer
  selector:
    app: cloudroute-backend
  ports:
    - port: 80
      targetPort: 8000
```

**Steps:**
1. Deploy to a cloud-managed cluster (GKE, EKS, AKS).
2. Create a LoadBalancer Service.
3. The cloud provider assigns an external IP.
4. Point your DNS to this external IP.

---

## 4. ExternalName

**What:** Maps a service to an external DNS name (CNAME alias).

**When to add:** When you need to reference external databases, APIs, or third-party services as if they were internal.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-api
spec:
  type: ExternalName
  externalName: external-api.example.com
```

**Steps:**
1. Create an ExternalName service for any external dependency.
2. Pods can now resolve `external-api` to the real external hostname.
3. Update `EXTERNAL_SERVICE_ALIAS` in your backend to match.

---

## 5. Gateway API

**What:** Modern Kubernetes networking API for advanced routing, traffic splitting, and TLS.

**When to add:** When you need path-based routing, host-based routing, traffic splitting, or TLS termination.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cloudroute-gateway
spec:
  gatewayClassName: istio
  listeners:
    - name: http
      protocol: HTTP
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: cloudroute-route
spec:
  parentRefs:
    - name: cloudroute-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: cloudroute-backend
          port: 8000
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: cloudroute-frontend
          port: 3000
```

**Steps:**
1. Install a Gateway API controller (Istio, Envoy Gateway, Cilium, etc.).
2. Create a Gateway and HTTPRoute resources.
3. Route `/api` traffic to the backend and `/` to the frontend.
4. Add TLS routes for HTTPS.

---

## 6. DaemonSet

**What:** Ensures one copy of a pod runs on every node (or a subset).

**When to add:** For logging agents, monitoring exporters, or network plugins that must run on every node.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cloudroute-logger
spec:
  selector:
    matchLabels:
      app: cloudroute-logger
  template:
    metadata:
      labels:
        app: cloudroute-logger
    spec:
      containers:
        - name: logger
          image: busybox
          command: ["sh", "-c", "while true; do echo logging; sleep 10; done"]
```

**Steps:**
1. Create a DaemonSet for a logging or monitoring sidecar.
2. Verify it runs on every node with `kubectl get pods -o wide`.
3. Use node selectors to limit which nodes run the DaemonSet.

---

## 7. StatefulSet

**What:** Manages stateful applications with stable network identity and persistent storage.

**When to add:** For databases, message queues, or any application that needs stable identities and durable storage.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cloudroute-db
spec:
  serviceName: cloudroute-db
  replicas: 3
  selector:
    matchLabels:
      app: cloudroute-db
  template:
    metadata:
      labels:
        app: cloudroute-db
    spec:
      containers:
        - name: postgres
          image: postgres:16
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
```

**Steps:**
1. Define a StatefulSet with volumeClaimTemplates.
2. Create a headless Service for stable DNS names (`cloudroute-db-0`, `cloudroute-db-1`, etc.).
3. Scale up/down with `kubectl scale statefulset`.

---

## 8. Init Containers

**What:** Run before the main container starts, performing setup or dependency checks.

**When to add:** For schema migrations, waiting for dependencies, or config generation.

```yaml
spec:
  initContainers:
    - name: wait-for-db
      image: busybox
      command: ["sh", "-c", "until nc -z cloudroute-db 5432; do echo waiting; sleep 2; done"]
  containers:
    - name: backend
      image: cloudroute-backend:latest
```

**Steps:**
1. Add an init container that waits for a dependency (e.g., database).
2. The main container starts only after init containers complete.
3. Use for schema migrations with tools like Flyway or Alembic.

---

## 9. Sidecars

**What:** Additional containers that run alongside the main application pod.

**When to add:** For service mesh proxies, log shipping, or health monitoring.

```yaml
spec:
  containers:
    - name: backend
      image: cloudroute-backend:latest
    - name: log-agent
      image: fluent/fluent-bit
      volumeMounts:
        - name: logs
          mountPath: /var/log
```

**Steps:**
1. Add a sidecar container to the same pod as the main app.
2. Share volumes for log files or config.
3. Use with Istio/Envoy for automatic mTLS and traffic management.

---

## 10. Persistent Volumes (PVC)

**What:** Storage abstraction that decouples from pod lifecycle.

**When to add:** For database storage, shared file systems, or model artifacts.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloudroute-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

**Steps:**
1. Create a PersistentVolumeClaim.
2. Mount it in your pod spec under `volumes` and `volumeMounts`.
3. Data persists across pod restarts and reschedules.

---

## 11. GitHub Actions CI/CD

**What:** Automate build, test, and deploy on every push.

**When to add:** After you have working Kubernetes manifests.

```yaml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and push
        run: |
          docker build -t your-registry/cloudroute-backend:$GITHUB_SHA ./cloudroute-lab-backend
          docker push your-registry/cloudroute-backend:$GITHUB_SHA
      - name: Deploy to cluster
        run: |
          kubectl set image deployment/cloudroute-backend backend=your-registry/cloudroute-backend:$GITHUB_SHA
```

**Steps:**
1. Add repository secrets: `DOCKER_REGISTRY`, `KUBE_CONFIG`.
2. Create the workflow file in `.github/workflows/deploy.yml`.
3. On every push to `main`, the workflow builds and deploys.
4. Use `KUBE_CONFIG` for cluster authentication.

---

## Recommended Order of Integration

1. **ClusterIP** — Internal service communication
2. **StatefulSet + PVC** — Database with persistent storage
3. **DaemonSet** — Logging/monitoring on every node
4. **NodePort** — Quick external access for testing
5. **LoadBalancer** — Production external traffic
6. **ExternalName** — External API references
7. **Gateway API** — Advanced routing and TLS
8. **Init Containers** — Dependency checks and migrations
9. **Sidecars** — Log shipping and service mesh
10. **GitHub Actions** — CI/CD automation

---

## Tips

- Start with Minikube or kind for local testing.
- Use `kubectl get all -n <namespace>` to inspect resources.
- Use `kubectl logs <pod-name>` to debug container output.
- Keep manifests in a `k8s/` directory in each repo.
- Separate environment configs with Kustomize overlays or Helm values.
