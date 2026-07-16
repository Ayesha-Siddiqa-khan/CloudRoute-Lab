# CloudRoute Lab Full Verification Guide

Use this after Terraform and GitHub Actions finish. It helps you confirm the complete lab, not only the frontend and backend.

## 1. Set Kubeconfig

Run this from your local terminal:

```powershell
$b64 = aws ssm get-parameter `
  --region us-east-1 `
  --name /terrapilot/cloudroute-lab/dev/kubernetes/kubeconfig/public-b64 `
  --with-decryption `
  --query 'Parameter.Value' `
  --output text

$env:KUBECONFIG = "$env:TEMP\cloudroute-lab-kubeconfig.yaml"
[System.IO.File]::WriteAllText(
  $env:KUBECONFIG,
  [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
)
```

Expected check:

```powershell
kubectl get nodes -o wide
```

You should see 2 Ready nodes:

```text
ip-10-0-1-127   Ready
ip-10-0-1-186   Ready   control-plane
```

## 2. Check The Main App

```powershell
kubectl get pods -n cloudroute-lab -o wide
kubectl get svc -n cloudroute-lab
kubectl get gateway,httproute -n cloudroute-lab
```

Expected services:

```text
cloudroute-frontend   ClusterIP   80/TCP
cloudroute-backend    ClusterIP   8000/TCP
external-api          ExternalName jsonplaceholder.typicode.com
```

## 3. Check Gateway API

```powershell
kubectl get gateway,httproute -A
kubectl get svc -n envoy-gateway-system
```

Expected:

```text
cloudroute-gateway   envoy-gateway   PROGRAMMED=True
cloudroute-route     Accepted=True
fastapi-route        Accepted=True
```

The external lab entry is the Envoy NodePort:

```text
envoy-cloudroute-lab-cloudroute-gateway-*   NodePort   80:30080/TCP
```

## 4. Check EBS Persistent Storage

```powershell
kubectl get storageclass
kubectl get pvc -A
kubectl get pod gp3-test-pod -n cloudroute-lab
```

Expected PVCs:

```text
cloudroute-lab   gp3-test-pvc               Bound   5Gi
stateful-app     postgres-data-postgres-0   Bound   20Gi
stateful-app     redis-data-redis-0         Bound   5Gi
```

Meaning: Kubernetes created AWS EBS volumes for your pods.

## 5. Check Monitoring

```powershell
kubectl get pods -n monitoring -o wide
kubectl get daemonset -n monitoring
kubectl get svc -n monitoring
```

Expected pods:

```text
prometheus      Running
grafana         Running
node-exporter   Running on both nodes
fluent-bit      Running on both nodes
```

Open Prometheus locally:

```powershell
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

Then open:

```text
http://localhost:9090
```

Open Grafana locally:

```powershell
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

Then open:

```text
http://localhost:3000
```

Login:

```text
username: admin
password: cloudroute-lab-grafana-admin
```

## 6. Check CloudWatch Logging

```powershell
aws logs describe-log-streams `
  --region us-east-1 `
  --log-group-name /cloudroute-lab/dev/kubernetes/containers `
  --order-by LastEventTime `
  --descending `
  --max-items 5
```

Expected: log streams for pods such as:

```text
cloudroute-backend
fastapi
calico-node
etcd
```

Meaning: Fluent Bit is collecting Kubernetes container logs and sending them to CloudWatch.

## 7. Check Stateful App

```powershell
kubectl get pods -n stateful-app -o wide
kubectl get svc -n stateful-app
kubectl get statefulset -n stateful-app
kubectl get cronjob -n stateful-app
```

Expected:

```text
postgres-0   Running
redis-0      Running
fastapi-*    Running
```

Check PostgreSQL:

```powershell
kubectl exec -n stateful-app postgres-0 -- pg_isready -U kubestate -d kubestate
```

Expected:

```text
/var/run/postgresql:5432 - accepting connections
```

Check Redis:

```powershell
kubectl exec -n stateful-app redis-0 -- redis-cli ping
```

Expected:

```text
PONG
```

Check FastAPI service from inside the cluster:

```powershell
kubectl run curl-debug `
  --rm -i `
  --restart=Never `
  --image=curlimages/curl:8.8.0 `
  -n stateful-app `
  -- curl -sS -m 10 http://fastapi/
```

Expected:

```text
{"detail":"Not Found"}
```

That is still a valid response. It means the service is reachable; the app simply does not define a `/` route.

## 8. Practice Backup CronJob

The scheduled backup object:

```powershell
kubectl get cronjob postgres-backup -n stateful-app
```

To manually create one backup job:

```powershell
kubectl create job `
  --from=cronjob/postgres-backup `
  manual-postgres-backup `
  -n stateful-app
```

Watch it:

```powershell
kubectl get jobs,pods -n stateful-app
kubectl logs -n stateful-app job/manual-postgres-backup
```

Then check S3:

```powershell
aws s3 ls s3://cloudroute-lab-dev-postgres-backups-2f82902a/postgres-backups/ --recursive
```

## 9. Beginner Mental Model

- Terraform builds AWS infrastructure: VPC, EC2, IAM, ECR, S3, CloudWatch, security groups.
- Kubernetes runs workloads on the EC2 nodes.
- GitHub Actions builds Docker images, pushes them to ECR, then applies Kubernetes manifests.
- Gateway API and Envoy expose HTTP traffic.
- EBS CSI creates persistent AWS volumes for Kubernetes PVCs.
- PostgreSQL and Redis are StatefulSets because they keep data.
- Prometheus collects metrics.
- Grafana displays metrics.
- Fluent Bit sends container logs to CloudWatch.
- The backup CronJob dumps PostgreSQL data to S3.

## 10. Important Cost Reminder

This lab creates AWS resources that can cost money, especially:

- EC2 instances
- NAT Gateway
- EBS volumes
- CloudWatch logs
- S3 storage

When you finish practicing, run your destroy workflow or Terraform destroy, then confirm ECR images are deleted or the ECR repositories allow force deletion.
