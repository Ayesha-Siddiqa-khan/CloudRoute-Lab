# Gateway API CRDs and Controller

## Prerequisites

Gateway API requires Custom Resource Definitions (CRDs) and a Gateway controller to be installed before use.

### Option A: Envoy Gateway (Recommended for Labs)

Envoy Gateway is lightweight and purpose-built for Gateway API.

```bash
# Install Gateway API CRDs
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway-crds.yaml

# Install Envoy Gateway
kubectl apply -f https://raw.githubusercontent.com/envoyproxy/gateway/v1.2.6/quickstart.yaml

# Verify installation
kubectl get gatewayclass
kubectl get pods -n envoy-gateway-system
```

### Option B: Cilium with Gateway API

If using Cilium as CNI (requires Cilium installation):

```bash
# Install Gateway API CRDs
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/gateway-crds.yaml

# Enable Cilium Gateway API (if Cilium is installed)
kubectl -n kube-system set env daemonset/cilium -c cilium-agent ENABLE_gateway_api=true
```

### Option C: Istio (Heavyweight)

Not recommended for small labs due to resource usage.

## Verify CRDs Installed

```bash
# Check if Gateway API CRDs exist
kubectl get crd | grep gateway

# Expected output:
# gatewayclasses.gateway.networking.k8s.io
# gateways.gateway.networking.k8s.io
# httproutes.gateway.networking.k8s.io
# referencegrants.gateway.networking.k8s.io
```

## Which Controller to Choose?

| Controller | Resource Usage | Complexity | Best For |
|------------|---------------|------------|----------|
| Envoy Gateway | Low (~100MB) | Simple | Labs, small clusters |
| Cilium | Medium | Medium | If already using Cilium CNI |
| Istio | High (~500MB+) | Complex | Production, service mesh |

**Recommendation for CloudRoute Lab:** Use **Envoy Gateway**.
