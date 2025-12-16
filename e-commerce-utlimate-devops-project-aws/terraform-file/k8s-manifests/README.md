# EKS Node Groups Deployment Guide

## Node Groups Configuration

### 1. Application Node Group
- **Purpose**: Web applications (NGINX, Apache, etc.)
- **Instance Type**: t3a.medium
- **Capacity**: ON_DEMAND
- **Scaling**: 1-5 nodes
- **Taint**: `workload-type=web:NoSchedule`

### 2. Backend Node Group
- **Purpose**: Backend applications (Node.js, Python, etc.)
- **Instance Type**: t3a.medium
- **Capacity**: ON_DEMAND
- **Scaling**: 1-4 nodes
- **Taint**: `workload-type=backend:NoSchedule`

### 3. Monitoring Node Group
- **Purpose**: Monitoring stack (Prometheus, Grafana, etc.)
- **Instance Types**: t3a.medium, t3.medium, t3a.large, t3.large
- **Capacity**: SPOT (cost optimization)
- **Scaling**: 1-3 nodes
- **Taint**: `workload-type=monitoring:NoSchedule`

## Deployment Commands

### Deploy EKS Cluster
```bash
./scripts/deploy.sh dev
```

### Update Kubeconfig
```bash
aws eks update-kubeconfig --region us-east-1 --name three-tier-vpc-dev
```

### Deploy Applications

#### 1. Deploy NGINX (Application Node Group)
```bash
kubectl apply -f k8s-manifests/nginx-application.yaml
```

#### 2. Deploy Node.js Backend (Backend Node Group)
```bash
kubectl apply -f k8s-manifests/nodejs-backend.yaml
```

#### 3. Deploy Monitoring Stack (Monitoring Node Group)
```bash
kubectl apply -f k8s-manifests/monitoring-stack.yaml
```

## Verify Deployments

### Check Node Groups
```bash
kubectl get nodes --show-labels
```

### Check Pod Placement
```bash
kubectl get pods -o wide --all-namespaces
```

### Check Services
```bash
kubectl get svc --all-namespaces
```

## Access Applications

### NGINX Application
```bash
kubectl port-forward svc/nginx-service 8080:80
# Access: http://localhost:8080
```

### Node.js Backend
```bash
kubectl port-forward svc/nodejs-backend-service 3000:3000
# Access: http://localhost:3000
```

### Grafana Dashboard
```bash
kubectl port-forward -n monitoring svc/grafana-service 3000:3000
# Access: http://localhost:3000
# Username: admin, Password: admin123
```

## Node Group Targeting

Each workload uses:
- **nodeSelector**: Targets specific node group by WorkloadType label
- **tolerations**: Allows scheduling on tainted nodes
- **taints**: Prevents other workloads from scheduling on dedicated nodes

This ensures workload isolation and optimal resource utilization across your EKS cluster.
