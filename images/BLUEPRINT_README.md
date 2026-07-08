# CloudRoute Lab - Infrastructure Blueprint README

## Overview

This document explains how to use the complete infrastructure blueprint for your CloudRoute Lab project.

## Files Created

### 1. INFRASTRUCTURE_BLUEPRINT.md
- **Purpose**: Complete infrastructure blueprint in Markdown format
- **Usage**: Read online, edit, or convert to other formats
- **Contains**: All 10 sections with detailed specifications

### 2. INFRASTRUCTURE_BLUEPRINT.html
- **Purpose**: Formatted HTML version for easy reading
- **Usage**: Open in any web browser
- **Contains**: Styled document with syntax highlighting

### 3. INFRASTRUCTURE_BLUEPRINT.pdf
- **Purpose**: PDF version for learning and reference
- **Usage**: Download, print, or share
- **Contains**: Same content as HTML, formatted for printing

## How to Use the Blueprint

### For InfraPilot
1. **Read the blueprint** - InfraPilot should parse the markdown file
2. **Extract resource definitions** - All AWS and Kubernetes resources are clearly defined
3. **Generate infrastructure** - Use the naming conventions and specifications provided
4. **Follow deployment order** - The 6-phase deployment plan ensures proper sequencing

### For Learning
1. **Start with Section 1** - Understand the VPC and network structure
2. **Review Section 2** - Learn about EC2 instances and compute
3. **Study Section 3** - Understand Kubernetes cluster setup
4. **Practice Section 4** - Learn about load balancing and services
5. **Implement Section 5** - Set up storage with EBS and PVCs
6. **Configure Section 6** - Set up container registry
7. **Automate Section 7** - Implement CI/CD with GitHub Actions
8. **Monitor Section 8** - Deploy Prometheus and Grafana
9. **Secure Section 9** - Apply security best practices
10. **Execute Section 10** - Follow the deployment plan

## Key Features of This Blueprint

### Cost-Aware Design
- **Total Monthly Cost**: ~$69 (on-demand)
- **Optimized with Spot**: ~$18/month (60% savings)
- **Student-Friendly**: Designed for limited resources

### Complete Coverage
- **AWS Infrastructure**: VPC, subnets, security groups, EC2, EBS
- **Kubernetes Cluster**: kubeadm, containerd, Calico CNI
- **Networking**: ClusterIP, NodePort, LoadBalancer, ExternalName, Gateway API
- **Storage**: EBS, PVCs, StorageClass, CSI driver
- **Monitoring**: Prometheus, Grafana, Node Exporter, Log Agent
- **Security**: IAM roles, security groups, RBAC, SSH access
- **CI/CD**: GitHub Actions with minimal secrets

### Learning-Oriented
- **Beginner-Friendly**: Clear explanations and justifications
- **Hands-On Practice**: Each section includes practice opportunities
- **Portfolio-Ready**: Professional structure for GitHub/LinkedIn
- **Step-by-Step**: Detailed deployment order

## Resource Naming Convention

All resources follow the `cloudroute-` prefix:
- **AWS**: cloudroute-vpc, cloudroute-master, cloudroute-worker, etc.
- **Kubernetes**: cloudroute-lab namespace, cloudroute-frontend, cloudroute-backend, etc.
- **Monitoring**: prometheus, grafana, node-exporter, log-agent

## Deployment Order Summary

1. **AWS Infrastructure** (InfraPilot)
2. **Kubernetes Cluster** (Manual/Automated)
3. **Storage Setup** (Manual)
4. **Monitoring Stack** (Manual)
5. **Application Deployment** (Manual)
6. **CI/CD Setup** (Manual)

## Cost Breakdown

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| EC2 Master | $30 | t3.medium on-demand |
| EC2 Worker | $30 | t3.medium on-demand |
| EBS Volumes | $4 | 20GB + 20GB + 10GB |
| Data Transfer | $5 | Estimated lab usage |
| **Total** | **$69** | On-demand pricing |

### Cost Optimization Options
- **Spot Instances**: $18/month (60% savings)
- **Reserved Instances**: $38/month (45% savings)
- **Free Tier**: May apply for new AWS accounts

## Security Considerations

### SSH Access
- Restrict to your IP only
- Use key-based authentication
- Disable root login

### Kubernetes Access
- Use RBAC for fine-grained control
- Create service accounts for applications
- Limit namespace access

### Network Security
- Restrict NodePort access
- Use NetworkPolicies
- Enable VPC Flow Logs

## Monitoring Resources

### Resource Allocation
- **Prometheus**: 200m CPU, 512Mi RAM
- **Grafana**: 100m CPU, 256Mi RAM
- **Node Exporter**: 50m CPU, 64Mi RAM (per node)
- **Log Agent**: 20m CPU, 32Mi RAM (per node)
- **Total Overhead**: ~2.3 GB RAM

### Access Points
- **Prometheus**: http://<master-ip>:30090
- **Grafana**: http://<master-ip>:30030
- **Node Exporter**: http://<node-ip>:9100/metrics

## Container Registry

### GitHub Container Registry (Recommended)
- **Frontend**: ghcr.io/<username>/cloudroute-frontend
- **Backend**: ghcr.io/<username>/cloudroute-backend
- **Cost**: Free for public repositories

### Image Tags
- **Latest**: For development
- **SHA-based**: For specific commits
- **Version**: For releases (v1.0.0)

## CI/CD Secrets

### Minimal Required Secrets
1. **KUBE_CONFIG**: Base64-encoded kubeconfig
2. **REGISTRY_URL**: ghcr.io/<username>
3. **AWS_REGION**: us-east-1 (if using ECR)

### No Additional Variables Needed
- Image names derived from repository
- Tags derived from git SHA
- Namespace hardcoded as cloudroute-lab

## Next Steps

1. **Review the blueprint** - Read all 10 sections carefully
2. **Customize variables** - Update IPs, usernames, and regions
3. **Start with Phase 1** - Create AWS infrastructure
4. **Follow the order** - Deploy in the recommended sequence
5. **Practice each concept** - Use the lab to learn Kubernetes networking
6. **Document your work** - Take screenshots and notes for portfolio

## Troubleshooting

### Common Issues
- **SSH Connection Failed**: Check security groups and key permissions
- **Kubernetes Join Failed**: Verify token and network connectivity
- **Pod Not Starting**: Check image pull secrets and resource availability
- **Service Not Accessible**: Verify selectors and NodePort ranges
- **Storage Not Working**: Check StorageClass and PVC binding

### Debug Commands
```bash
# Check nodes
kubectl get nodes -o wide

# Check pods
kubectl get pods -A -o wide

# Check services
kubectl get svc -A

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check logs
kubectl logs <pod-name> -n <namespace>
```

## Learning Resources

### Official Documentation
- **Kubernetes**: https://kubernetes.io/docs/
- **AWS**: https://docs.aws.amazon.com/
- **Gateway API**: https://gateway-api.sigs.k8s.io/

### Practice Areas
1. **Services**: ClusterIP, NodePort, LoadBalancer, ExternalName
2. **Workloads**: Deployment, StatefulSet, DaemonSet
3. **Storage**: PVC, PV, StorageClass
4. **Networking**: Gateway API, NetworkPolicies
5. **Monitoring**: Prometheus, Grafana, metrics
6. **CI/CD**: GitHub Actions, container registry

## Support

For issues or questions:
- Check the troubleshooting section
- Review official documentation
- Use Kubernetes community resources
- Ask in relevant forums or communities

---

**Created**: 2026-07-08  
**Project**: CloudRoute Lab  
**Version**: 1.0  
**Author**: InfraPilot  
**Purpose**: Complete infrastructure blueprint for student Kubernetes lab
