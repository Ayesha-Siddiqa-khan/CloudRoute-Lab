# AWS EBS Storage

This folder contains StorageClass and PVC examples for AWS EBS dynamic provisioning.

## Components

| File | Purpose |
|------|---------|
| `gp3-storageclass.yaml` | StorageClass for gp3 EBS volumes |

## Prerequisites

### 1. EBS CSI Driver IAM Permissions

Terraform attaches `AmazonEBSCSIDriverPolicyV2` to both master and worker EC2 roles. This grants:
- `ec2:CreateVolume`
- `ec2:DeleteVolume`
- `ec2:AttachVolume`
- `ec2:DetachVolume`
- `ec2:DescribeVolumes`
- `ec2:DescribeInstances`
- `ec2:CreateTags`
- `ec2:DeleteTags`

### 2. Install EBS CSI Driver

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.62"
```

### 3. Verify CSI Driver

```bash
kubectl get pods -n kube-system | grep ebs
```

## Install StorageClass

```bash
kubectl apply -f k8s/storage/gp3-storageclass.yaml
```

## Verify StorageClass

```bash
kubectl get storageclass
```

Expected output:
```
NAME   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp3 (default)   ebs.csi.aws.com   Delete          WaitForFirstConsumer   true                   1m
```

## Why WaitForFirstConsumer?

`WaitForFirstConsumer` delays volume creation until a pod is scheduled. This ensures:

1. **AZ matching** - EBS volumes are created in the same availability zone as the EC2 instance
2. **No conflicts** - Volume is created where the pod actually runs
3. **Better performance** - No cross-AZ latency

Without this, a volume might be created in `us-east-1a` but the pod schedules in `us-east-1b`, causing attachment failures.

## Create a PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  namespace: cloudroute-lab
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 5Gi
```

```bash
kubectl apply -f my-pvc.yaml
kubectl get pvc -n cloudroute-lab
```

## Verify PVC is Working

```bash
# Check PVC status
kubectl get pvc -n cloudroute-lab

# Check PV was created
kubectl get pv

# Check EBS volume in AWS
aws ec2 describe-volumes --filters "Name=tag:ManagedBy,Values=kubernetes"
```

## Use PVC in a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pvc
  namespace: cloudroute-lab
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "echo 'data' > /data/test.txt && sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: my-pvc
```

## Cleanup

```bash
kubectl delete pvc my-pvc -n cloudroute-lab
kubectl delete -f k8s/storage/gp3-storageclass.yaml
```
