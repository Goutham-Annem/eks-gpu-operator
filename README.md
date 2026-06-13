# eks-gpu-operator

> NVIDIA GPU Operator on EKS — automated driver install, time-slicing, MIG configuration, and device plugin management via Terraform + Helm.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## What this covers

- **NVIDIA GPU Operator** — automates driver + container toolkit + device plugin install
- **Time-slicing** — share one GPU across multiple pods (cost optimization for dev/test)
- **MIG (Multi-Instance GPU)** — partition A100/H100 for isolated workloads
- **Node feature discovery** — auto-labels nodes with GPU capabilities
- **DCGM Exporter** — GPU metrics (utilization, memory, temperature) to Prometheus

## Architecture

```
EKS Node (g5.xlarge / p4d.24xlarge)
│
├── GPU Operator DaemonSet
│   ├── Driver installer (init)
│   ├── NVIDIA Container Toolkit
│   ├── NVIDIA Device Plugin
│   └── DCGM Exporter (metrics)
│
└── Workload Pods
    ├── resources.limits.nvidia.com/gpu: 1   (full GPU)
    ├── resources.limits.nvidia.com/gpu: 0.5 (time-sliced)
    └── resources.limits.nvidia.com/mig-1g.10gb: 1 (MIG slice)
```

## Install

```bash
cd terraform/
terraform init
terraform apply -var="cluster_name=my-cluster"

# Verify GPU Operator is running
kubectl get pods -n gpu-operator

# Check GPU resources are visible on nodes
kubectl get nodes -o custom-columns="NAME:.metadata.name,GPUs:.status.allocatable.nvidia\.com/gpu"
```

## Time-slicing config

Allows multiple pods to share one physical GPU — ideal for dev workloads:

```bash
kubectl apply -f manifests/time-slicing-config.yaml

# Each pod now gets 1/4 of the GPU
# 4 pods can run simultaneously on 1 physical GPU
```

## DCGM Metrics

After install, Prometheus will scrape:

- `DCGM_FI_DEV_GPU_UTIL` — GPU utilization %
- `DCGM_FI_DEV_MEM_COPY_UTIL` — memory bandwidth utilization
- `DCGM_FI_DEV_FB_USED` — framebuffer memory used (MB)
- `DCGM_FI_DEV_POWER_USAGE` — power draw (watts)
- `DCGM_FI_DEV_SM_CLOCK` — SM clock speed

## Files

```
eks-gpu-operator/
├── manifests/
│   ├── gpu-operator.yaml         # ClusterPolicy CR
│   └── time-slicing-config.yaml  # ConfigMap for time-slicing
└── terraform/
    └── main.tf                   # Helm release + Node Feature Discovery
```

## License

MIT — by [Goutham Annem](https://github.com/Goutham-Annem)
