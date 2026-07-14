# CloudRoute Lab Post-Deployment Command Plan

Use this file after GitHub Actions shows the deployment completed successfully.

Goal: prove that every part of CloudRoute Lab works, understand what each command checks, and collect useful outputs for learning or screenshots.

## 0. Before You Start

Run commands from a machine that has working `kubectl` access to the cluster.

If you are on the Kubernetes control-plane EC2 instance, use the private kubeconfig:

```bash
cp ~/.kube/config-private ~/.kube/config
kubectl get nodes
```

If you are using your laptop or GitHub Actions, use the public kubeconfig from `KUBE_CONFIG_DATA`.

Create a folder to save outputs:

```bash
mkdir -p cloudroute-checks
```

Save a timestamp:

```bash
date | tee cloudroute-checks/00-check-time.txt
```

Expected output:

```text
Mon Jul 13 ... UTC 2026
```

## 1. Check Cluster Nodes

Command:

```bash
kubectl get nodes -o wide | tee cloudroute-checks/01-nodes.txt
```

What this checks:

- The Kubernetes control-plane node exists.
- The worker node joined the cluster.
- Nodes are `Ready`.

Expected output shape:

```text
NAME            STATUS   ROLES           AGE   VERSION   INTERNAL-IP
ip-10-0-1-xxx   Ready    control-plane    ...   v1.xx.x   10.0.1.xxx
ip-10-0-1-yyy   Ready    <none>           ...   v1.xx.x   10.0.1.yyy
```

Good result:

- `STATUS` should be `Ready` for all nodes.

If not good:

```bash
kubectl describe node <NODE_NAME>
sudo systemctl status kubelet --no-pager
```

## 2. Check All Namespaces

Command:

```bash
kubectl get ns | tee cloudroute-checks/02-namespaces.txt
```

Expected important namespaces:

```text
cloudroute-lab
envoy-gateway-system
kube-system
```

Optional namespaces if installed later:

```text
monitoring
stateful-app
```

## 3. Check Application Pods

Command:

```bash
kubectl get pods -n cloudroute-lab -o wide | tee cloudroute-checks/03-app-pods.txt
```

What this checks:

- Frontend pod is running.
- Backend pod is running.
- Pods are scheduled on a node.

Expected output shape:

```text
NAME                                   READY   STATUS    RESTARTS   AGE
cloudroute-frontend-xxxxxxxxx-xxxxx    1/1     Running   0          ...
cloudroute-backend-xxxxxxxxx-xxxxx     1/1     Running   0          ...
```

Good result:

- `READY` is `1/1`
- `STATUS` is `Running`
- `RESTARTS` is usually `0`

If not good:

```bash
kubectl describe pods -n cloudroute-lab
kubectl get events -n cloudroute-lab --sort-by=.lastTimestamp
```

## 4. Check Deployments

Command:

```bash
kubectl get deployments -n cloudroute-lab | tee cloudroute-checks/04-deployments.txt
```

Expected output:

```text
NAME                  READY   UP-TO-DATE   AVAILABLE
cloudroute-frontend   1/1     1            1
cloudroute-backend    1/1     1            1
```

Check rollout status:

```bash
kubectl rollout status deployment/cloudroute-frontend -n cloudroute-lab | tee cloudroute-checks/04a-frontend-rollout.txt
kubectl rollout status deployment/cloudroute-backend -n cloudroute-lab | tee cloudroute-checks/04b-backend-rollout.txt
```

Expected output:

```text
deployment "cloudroute-frontend" successfully rolled out
deployment "cloudroute-backend" successfully rolled out
```

## 5. Check Services

Command:

```bash
kubectl get svc -n cloudroute-lab -o wide | tee cloudroute-checks/05-services.txt
```

What this checks:

- Frontend ClusterIP Service exists.
- Backend ClusterIP Service exists.
- ExternalName example exists.

Expected output shape:

```text
NAME                  TYPE           CLUSTER-IP      PORT(S)
cloudroute-frontend   ClusterIP      10.x.x.x        80/TCP
cloudroute-backend    ClusterIP      10.x.x.x        8000/TCP
external-api          ExternalName   <none>          <none>
```

## 6. Test Backend From Inside The Cluster

Command:

```bash
kubectl run curl-test -n cloudroute-lab --rm -i --restart=Never --image=curlimages/curl -- \
  curl -s http://cloudroute-backend.cloudroute-lab.svc.cluster.local:8000/health | tee cloudroute-checks/06-backend-health.txt
```

Expected output:

```json
{"status":"healthy","environment":"production"}
```

Test backend API:

```bash
kubectl run curl-test-api -n cloudroute-lab --rm -i --restart=Never --image=curlimages/curl -- \
  curl -s http://cloudroute-backend.cloudroute-lab.svc.cluster.local:8000/api/status | tee cloudroute-checks/06a-backend-api-status.txt
```

Expected output shape:

```json
{"app":"CloudRoute Lab","version":"1.0.0","environment":"production"}
```

## 7. Test Frontend From Inside The Cluster

Command:

```bash
kubectl run curl-test-frontend -n cloudroute-lab --rm -i --restart=Never --image=curlimages/curl -- \
  curl -I http://cloudroute-frontend.cloudroute-lab.svc.cluster.local | tee cloudroute-checks/07-frontend-headers.txt
```

Expected output:

```text
HTTP/1.1 200 OK
```

## 8. Check Gateway API CRDs

Command:

```bash
kubectl get crd | grep gateway | tee cloudroute-checks/08-gateway-crds.txt
```

Expected important CRDs:

```text
gatewayclasses.gateway.networking.k8s.io
gateways.gateway.networking.k8s.io
httproutes.gateway.networking.k8s.io
envoyproxies.gateway.envoyproxy.io
```

## 9. Check Envoy Gateway Controller

Command:

```bash
kubectl get pods -n envoy-gateway-system -o wide | tee cloudroute-checks/09-envoy-gateway-pods.txt
```

Expected output shape:

```text
NAME                              READY   STATUS    RESTARTS
envoy-gateway-xxxxxxxxxx-xxxxx    1/1     Running   0
```

Check Helm release:

```bash
helm list -n envoy-gateway-system | tee cloudroute-checks/09a-envoy-helm.txt
```

Expected output:

```text
NAME   NAMESPACE              STATUS    CHART
eg     envoy-gateway-system   deployed  gateway-helm-...
```

## 10. Check Gateway Resources

Command:

```bash
kubectl get gatewayclass | tee cloudroute-checks/10-gatewayclass.txt
kubectl get gateway -n cloudroute-lab -o wide | tee cloudroute-checks/10a-gateway.txt
kubectl get httproute -n cloudroute-lab -o wide | tee cloudroute-checks/10b-httproute.txt
```

Expected output:

```text
envoy-gateway
cloudroute-gateway
cloudroute-route
```

Describe Gateway:

```bash
kubectl describe gateway cloudroute-gateway -n cloudroute-lab | tee cloudroute-checks/10c-gateway-describe.txt
```

Good result:

- Look for `Accepted=True`
- Look for `Programmed=True`

Describe HTTPRoute:

```bash
kubectl describe httproute cloudroute-route -n cloudroute-lab | tee cloudroute-checks/10d-httproute-describe.txt
```

Good result:

- Parent Gateway is accepted.
- Backend references are resolved.

## 11. Find Gateway NodePort

Envoy Gateway creates a Service for the Gateway data plane.

Command:

```bash
kubectl get svc -A | grep -E 'envoy|gateway' | tee cloudroute-checks/11-gateway-services.txt
```

Expected:

- One Envoy data-plane Service should expose NodePort `30080`.

Example output shape:

```text
cloudroute-lab   envoy-cloudroute-gateway-...   NodePort   ...   80:30080/TCP
```

If you do not see `30080`, describe the EnvoyProxy:

```bash
kubectl describe envoyproxy cloudroute-envoy-nodeport -n cloudroute-lab | tee cloudroute-checks/11a-envoyproxy-describe.txt
```

## 12. Test Through Worker NodePort

Get worker node IP:

```bash
kubectl get nodes -o wide | tee cloudroute-checks/12-node-ips.txt
```

From a machine that can reach the worker node, test:

```bash
curl -I http://<WORKER_NODE_PUBLIC_OR_PRIVATE_IP>:30080/ | tee cloudroute-checks/12a-nodeport-frontend.txt
curl -s http://<WORKER_NODE_PUBLIC_OR_PRIVATE_IP>:30080/api/status | tee cloudroute-checks/12b-nodeport-backend.txt
```

Expected:

```text
HTTP/1.1 200 OK
```

and:

```json
{"app":"CloudRoute Lab","version":"1.0.0","environment":"production"}
```

## 13. Test Through NGINX External Load Balancer

Use your NGINX EC2 public IP or DNS:

```bash
curl -I http://<NGINX_PUBLIC_IP>/ | tee cloudroute-checks/13-nginx-frontend.txt
curl -s http://<NGINX_PUBLIC_IP>/api/status | tee cloudroute-checks/13a-nginx-backend.txt
```

Expected:

```text
HTTP/1.1 200 OK
```

and:

```json
{"app":"CloudRoute Lab","version":"1.0.0","environment":"production"}
```

If this fails:

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo tail -n 100 /var/log/nginx/cloudroute-lab-error.log
```

## 14. Check Current Images Running In Kubernetes

Command:

```bash
kubectl get deployment cloudroute-frontend -n cloudroute-lab -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}' | tee cloudroute-checks/14-frontend-image.txt
kubectl get deployment cloudroute-backend -n cloudroute-lab -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}' | tee cloudroute-checks/14a-backend-image.txt
```

Expected output shape:

```text
257536659737.dkr.ecr.us-east-1.amazonaws.com/cloudroute-lab-frontend:<commit-sha>
257536659737.dkr.ecr.us-east-1.amazonaws.com/cloudroute-lab-backend:<commit-sha>
```

## 15. Check ECR Repositories

Command:

```bash
aws ecr describe-repositories --region us-east-1 | tee cloudroute-checks/15-ecr-repositories.json
```

Expected:

- `cloudroute-lab-frontend`
- `cloudroute-lab-backend`

List pushed image tags:

```bash
aws ecr list-images --repository-name cloudroute-lab-frontend --region us-east-1 | tee cloudroute-checks/15a-frontend-images.json
aws ecr list-images --repository-name cloudroute-lab-backend --region us-east-1 | tee cloudroute-checks/15b-backend-images.json
```

Expected:

- Image tag should match the GitHub commit SHA from the successful Actions run.

## 16. Check GitHub Actions Deployment Inputs

Use GitHub UI:

```text
Repository -> Settings -> Secrets and variables -> Actions
```

Expected secret:

```text
KUBE_CONFIG_DATA
```

Expected variables:

```text
AWS_REGION=us-east-1
AWS_ROLE_ARN=arn:aws:iam::<account-id>:role/cloudroute-lab-dev-github-actions-oidc
ECR_REGISTRY=257536659737.dkr.ecr.us-east-1.amazonaws.com
FRONTEND_IMAGE_NAME=cloudroute-lab-frontend
BACKEND_IMAGE_NAME=cloudroute-lab-backend
```

## 17. Check Terraform Outputs

Command:

```bash
terraform -chdir=terraform output | tee cloudroute-checks/17-terraform-outputs.txt
```

Important outputs to verify:

```text
github_actions_role_arn
github_actions_variables
kubernetes_worker_instances
gateway_http_node_port
kubernetes_api_allowed_cidrs
backend_ecr_repository_url
frontend_ecr_repository_url
```

Good result:

- `gateway_http_node_port` should be `30080`
- `kubernetes_api_allowed_cidrs` includes `0.0.0.0/0` for this lab

## 18. Check Security Group For Kubernetes API

Get security group output:

```bash
terraform -chdir=terraform output created_security_group_ids | tee cloudroute-checks/18-security-groups.txt
```

Then verify in AWS Console:

```text
EC2 -> Security Groups -> cloudroute-lab-dev-ec2-sg -> Inbound rules
```

Expected lab rule:

```text
TCP 6443 from 0.0.0.0/0
TCP 6443 from 10.0.0.0/16
```

Important:

For production, do not leave Kubernetes API open to `0.0.0.0/0`. Use a self-hosted runner inside the VPC or trusted IPs.

## 19. Install And Check Monitoring

If you have not installed monitoring yet, create Grafana secret first:

```bash
cp k8s/monitoring/grafana-secret.example.yaml k8s/monitoring/grafana-secret.yaml
```

Edit `k8s/monitoring/grafana-secret.yaml` and set a real password.

Apply monitoring:

```bash
kubectl apply -f k8s/monitoring/namespace.yaml
kubectl apply -f k8s/monitoring/prometheus-serviceaccount.yaml
kubectl apply -f k8s/monitoring/prometheus-clusterrole.yaml
kubectl apply -f k8s/monitoring/prometheus-clusterrolebinding.yaml
kubectl apply -f k8s/monitoring/prometheus-configmap.yaml
kubectl apply -f k8s/monitoring/grafana-datasources.yaml
kubectl apply -f k8s/monitoring/grafana-secret.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
kubectl apply -f k8s/monitoring/prometheus-service.yaml
kubectl apply -f k8s/monitoring/grafana-deployment.yaml
kubectl apply -f k8s/monitoring/grafana-service.yaml
kubectl apply -f k8s/monitoring/node-exporter-daemonset.yaml
```

Check monitoring pods:

```bash
kubectl get pods -n monitoring -o wide | tee cloudroute-checks/19-monitoring-pods.txt
```

Expected:

```text
prometheus   Running
grafana      Running
node-exporter pods Running
```

Access Grafana:

```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

Open:

```text
http://localhost:3000
```

## 20. Install And Check CloudWatch Logging

Apply Fluent Bit:

```bash
kubectl apply -f k8s/monitoring/fluent-bit-serviceaccount.yaml
kubectl apply -f k8s/monitoring/fluent-bit-clusterrole.yaml
kubectl apply -f k8s/monitoring/fluent-bit-clusterrolebinding.yaml
kubectl apply -f k8s/monitoring/fluent-bit-configmap.yaml
kubectl apply -f k8s/monitoring/fluent-bit-daemonset.yaml
```

Check Fluent Bit:

```bash
kubectl get daemonset -n monitoring | tee cloudroute-checks/20-fluent-bit-daemonset.txt
kubectl get pods -n monitoring -l app.kubernetes.io/name=fluent-bit -o wide | tee cloudroute-checks/20a-fluent-bit-pods.txt
kubectl logs -n monitoring daemonset/fluent-bit --tail=100 | tee cloudroute-checks/20b-fluent-bit-logs.txt
```

Expected:

```text
fluent-bit desired number scheduled equals current number scheduled
```

Check CloudWatch log streams:

```bash
aws logs describe-log-streams \
  --log-group-name /cloudroute-lab/dev/kubernetes/containers \
  --region us-east-1 | tee cloudroute-checks/20c-cloudwatch-streams.json
```

Expected:

- Log streams exist for Kubernetes container logs.

## 21. Install And Check EBS gp3 PVC

Install EBS CSI Driver if not already installed:

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.62"
```

Apply StorageClass and test PVC:

```bash
kubectl apply -f k8s/storage/gp3-storageclass.yaml
kubectl apply -f k8s/storage/pvc-test.yaml
kubectl get storageclass | tee cloudroute-checks/21-storageclass.txt
kubectl get pvc -n cloudroute-lab | tee cloudroute-checks/21a-pvc.txt
kubectl get pod gp3-test-pod -n cloudroute-lab | tee cloudroute-checks/21b-pvc-test-pod.txt
```

Expected:

```text
gp3
gp3-test-pvc   Bound
gp3-test-pod   Running
```

Clean up test PVC when finished:

```bash
kubectl delete -f k8s/storage/pvc-test.yaml
```

## 22. Optional Stateful App Check

Only do this after you create real local secret files from examples:

```bash
cp k8s/stateful-app/postgres-secret.example.yaml k8s/stateful-app/postgres-secret.yaml
cp k8s/stateful-app/app-secret.example.yaml k8s/stateful-app/app-secret.yaml
```

Edit both files and replace placeholders.

Apply:

```bash
kubectl apply -f k8s/stateful-app/namespace.yaml
kubectl apply -f k8s/stateful-app/configmap.yaml
kubectl apply -f k8s/stateful-app/postgres-secret.yaml
kubectl apply -f k8s/stateful-app/app-secret.yaml
kubectl apply -f k8s/stateful-app/postgres-service.yaml
kubectl apply -f k8s/stateful-app/postgres-statefulset.yaml
kubectl apply -f k8s/stateful-app/redis-service.yaml
kubectl apply -f k8s/stateful-app/redis-statefulset.yaml
kubectl get pods -n stateful-app -o wide | tee cloudroute-checks/22-stateful-pods.txt
kubectl get pvc -n stateful-app | tee cloudroute-checks/22a-stateful-pvc.txt
```

Expected:

```text
postgres-0   Running
redis-0      Running
PVCs         Bound
```

## 23. Beginner Learning Questions

After running the commands, answer these in your own words:

1. Which command proved the frontend pod is running?
2. Which command proved the backend API works?
3. Which resource sends `/api` traffic to the backend?
4. Which port does NGINX forward to?
5. Which Kubernetes resource gives the frontend a stable internal address?
6. Why does Kubernetes need an ECR image pull secret?
7. What is the difference between a Deployment and a Service?
8. What is the difference between a NodePort and a ClusterIP?
9. Why is `WaitForFirstConsumer` useful for EBS volumes?
10. Why should `0.0.0.0/0` on port `6443` be removed for production?

## 24. Common Problems And Fast Checks

### Pod is not Running

```bash
kubectl describe pod <POD_NAME> -n cloudroute-lab
kubectl get events -n cloudroute-lab --sort-by=.lastTimestamp
```

Look for:

```text
ImagePullBackOff
CrashLoopBackOff
FailedScheduling
Readiness probe failed
```

### Image Pull Fails

```bash
kubectl get secret ecr-registry -n cloudroute-lab
kubectl describe pod <POD_NAME> -n cloudroute-lab
```

Fix:

- Re-run GitHub Actions.
- Confirm `ECR_REGISTRY`, `FRONTEND_IMAGE_NAME`, and `BACKEND_IMAGE_NAME`.

### Gateway Does Not Work

```bash
kubectl get gatewayclass
kubectl get gateway -n cloudroute-lab
kubectl describe gateway cloudroute-gateway -n cloudroute-lab
kubectl describe httproute cloudroute-route -n cloudroute-lab
```

Look for:

```text
Accepted=True
Programmed=True
ResolvedRefs=True
```

### GitHub Actions Cannot Deploy

Check:

```bash
terraform -chdir=terraform output kubernetes_api_allowed_cidrs
```

For this lab, expected:

```text
0.0.0.0/0
10.0.0.0/16
```

Also confirm `KUBE_CONFIG_DATA` uses the current public control-plane IP.

## 25. Final Success Checklist

Your deployment is healthy when all are true:

- [ ] `kubectl get nodes` shows all nodes `Ready`
- [ ] frontend pod is `Running`
- [ ] backend pod is `Running`
- [ ] frontend Deployment is `1/1`
- [ ] backend Deployment is `1/1`
- [ ] backend `/health` returns healthy
- [ ] backend `/api/status` returns CloudRoute Lab status
- [ ] GatewayClass exists
- [ ] Gateway exists
- [ ] HTTPRoute exists
- [ ] Envoy Gateway pod is running
- [ ] NodePort `30080` exists for Gateway traffic
- [ ] NGINX public IP opens the frontend
- [ ] `http://<NGINX_PUBLIC_IP>/api/status` reaches backend
- [ ] ECR has frontend and backend images
- [ ] GitHub Actions latest run is green
- [ ] Monitoring is running, if installed
- [ ] Fluent Bit sends logs to CloudWatch, if installed
- [ ] PVC test is `Bound`, if storage is installed

## 26. Recommended Next Learning Steps

1. Draw the traffic flow by hand.
2. Take screenshots of every successful command output.
3. Open the frontend in a browser through NGINX.
4. Open `/api/status` through NGINX.
5. Delete one frontend pod and watch Kubernetes recreate it:

```bash
kubectl delete pod -n cloudroute-lab -l app=cloudroute-frontend
kubectl get pods -n cloudroute-lab -w
```

6. Scale frontend to 2 replicas:

```bash
kubectl scale deployment cloudroute-frontend -n cloudroute-lab --replicas=2
kubectl get pods -n cloudroute-lab
```

7. Scale back to 1 replica:

```bash
kubectl scale deployment cloudroute-frontend -n cloudroute-lab --replicas=1
```

8. Read the logs:

```bash
kubectl logs -n cloudroute-lab deployment/cloudroute-frontend
kubectl logs -n cloudroute-lab deployment/cloudroute-backend
```

9. Study one Kubernetes object deeply:

```bash
kubectl get deployment cloudroute-frontend -n cloudroute-lab -o yaml
```

10. When done for the day, review cost guardrails:

```bash
cat COST_GUARDRAILS.md
```

