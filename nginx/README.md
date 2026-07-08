# NGINX External Load Balancer

Use this when NGINX runs on an EC2 instance outside the Kubernetes data plane and forwards public HTTP traffic to the Gateway API NodePort on worker nodes.

Traffic flow:

```text
User -> NGINX EC2 port 80 -> Kubernetes worker node port 30080 -> Envoy Gateway -> HTTPRoute -> ClusterIP Service -> Pod
```

Setup:

```bash
sudo apt-get update
sudo apt-get install -y nginx
sudo cp nginx/cloudroute-lab.conf.example /etc/nginx/sites-available/cloudroute-lab
sudo nano /etc/nginx/sites-available/cloudroute-lab
sudo ln -sf /etc/nginx/sites-available/cloudroute-lab /etc/nginx/sites-enabled/cloudroute-lab
sudo nginx -t
sudo systemctl reload nginx
```

Replace `REPLACE_WITH_WORKER_PRIVATE_IP` with a worker node private IP from:

```bash
terraform -chdir=terraform output kubernetes_worker_instances
```

If you have more than one worker, add one `server WORKER_PRIVATE_IP:30080;` line per worker in the `upstream` block.
