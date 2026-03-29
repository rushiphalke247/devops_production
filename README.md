# Production DevOps Platform on AWS

A complete DevOps platform featuring CI/CD pipelines with Jenkins, containerized microservices on a self-managed Kubernetes cluster (kubeadm), SonarQube code analysis, Trivy security scanning, and Prometheus + Grafana monitoring — all running on **3 EC2 instances**.

## Architecture

```
                            ┌──────────────────────────────┐
                            │        AWS VPC (10.0.0.0/16) │
                            │                              │
  ┌──────────────────────────────────────────────────────────────────────┐
  │                          Public Subnets                             │
  │                                                                      │
  │  ┌─────────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
  │  │  EC2: Jenkins Server │  │ EC2: K8s Master  │  │ EC2: K8s Worker│  │
  │  │  (t2.large)         │  │ (t2.medium)      │  │ (t2.medium)    │  │
  │  │                     │  │                  │  │                │  │
  │  │  - Jenkins :8080    │  │  - Control Plane │  │  - Kubelet     │  │
  │  │  - SonarQube :9000  │  │  - kubeadm       │  │  - Pods run    │  │
  │  │  - Docker           │  │  - Flannel CNI   │  │    here        │  │
  │  │  - Trivy            │  │  - Prometheus    │  │                │  │
  │  │                     │  │  - Grafana       │  │                │  │
  │  └────────┬────────────┘  └────────┬─────────┘  └───────┬────────┘  │
  │           │                        │                     │           │
  └───────────┼────────────────────────┼─────────────────────┼───────────┘
              │                        │                     │
              │          CI/CD Pipeline│  kubeadm join       │
              │     ┌──────────────────┤◄────────────────────┘
              │     │                  │
              ▼     ▼                  ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │                      Internet Gateway                                │
  └──────────────────────────────┬────────────────────────────────────────┘
                                 │
                              Users / Git
```

## CI/CD Pipeline Flow

```
Git Push → Jenkins → SonarQube Analysis → Trivy Scan → Docker Build → Docker Hub Push → SSH Deploy to K8s
```

## Project Structure

```
devops-project/
├── terraform/                     # Infrastructure as Code (6 files)
│   ├── provider.tf                # AWS provider config
│   ├── variables.tf               # Input variables
│   ├── vpc.tf                     # VPC, Subnets, IGW, NAT, Route Tables
│   ├── security-groups.tf         # Jenkins+SonarQube SG, K8s SG
│   ├── ec2.tf                     # 3 EC2: Jenkins, K8s Master, K8s Worker
│   └── outputs.tf                 # IPs and URLs
├── docker/                        # Containerized Microservices
│   ├── python-api/                # Flask REST API
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   ├── node-frontend/             # Express.js Frontend
│   │   ├── server.js
│   │   ├── package.json
│   │   └── Dockerfile
│   └── docker-compose.yml         # Local dev stack
├── kubernetes/                    # K8s Manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── deployments.yaml           # 2 deployments with probes + rolling update
│   ├── services.yaml              # ClusterIP + LoadBalancer
│   ├── ingress.yaml               # NGINX path-based routing
│   └── hpa.yaml                   # Auto-scaling (CPU 70%)
├── jenkins/
│   └── Jenkinsfile                # 6-stage CI/CD pipeline
├── ansible/
│   ├── inventory/hosts
│   └── playbooks/
│       ├── setup-docker.yml       # Docker on all nodes
│       ├── setup-jenkins.yml      # Jenkins + Trivy + kubectl
│       ├── setup-k8s-cluster.yml  # kubeadm init + join
│       └── setup-monitoring.yml   # Prometheus + Grafana on master
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml         # Scrape configs
│   │   └── alert-rules.yml        # CPU, memory, pod alerts
│   ├── grafana/
│   │   ├── datasource.yml
│   │   └── dashboard.yml
│   └── alertmanager/
│       └── alertmanager.yml       # Email/Slack routing
├── scripts/setup.sh
├── .gitignore
└── README.md
```

## Tools & Technologies

| Category               | Tools                                |
|-------------------------|--------------------------------------|
| Cloud                   | AWS (EC2, VPC)                       |
| IaC                     | Terraform                            |
| Containers              | Docker, Docker Compose               |
| Orchestration           | Kubernetes (kubeadm on EC2)          |
| CI/CD                   | Jenkins                              |
| Code Quality            | SonarQube                            |
| Security Scanning       | Trivy                                |
| Config Management       | Ansible                              |
| Monitoring              | Prometheus, Grafana, Alertmanager    |
| OS                      | Linux (Ubuntu 22.04)                 |

## EC2 Servers

| Server             | Instance Type | Runs                                        |
|--------------------|---------------|---------------------------------------------|
| Jenkins Server     | t2.large      | Jenkins, SonarQube (Docker), Docker, Trivy  |
| K8s Master         | t2.medium     | Control Plane, Prometheus, Grafana          |
| K8s Worker         | t2.medium     | Worker Node (runs app pods)                 |

## Getting Started

### Prerequisites
- AWS account with CLI configured
- Terraform >= 1.5
- Ansible installed locally
- Docker Hub account

### Step 1: Provision 3 EC2 Instances
```bash
cd terraform
terraform init
terraform plan
terraform apply

# Note the output IPs:
# jenkins_public_ip, k8s_master_public_ip, k8s_worker_public_ip
```

### Step 2: Update Ansible Inventory
```bash
# Edit ansible/inventory/hosts — replace <JENKINS_IP>, <K8S_MASTER_IP>, <K8S_WORKER_IP>
```

### Step 3: Configure Servers with Ansible
```bash
cd ansible

# Install Docker on all 3 servers
ansible-playbook -i inventory/hosts playbooks/setup-docker.yml

# Setup Jenkins + SonarQube + Trivy
ansible-playbook -i inventory/hosts playbooks/setup-jenkins.yml

# Setup Kubernetes cluster (master init + worker join)
ansible-playbook -i inventory/hosts playbooks/setup-k8s-cluster.yml

# Setup Prometheus + Grafana on master
ansible-playbook -i inventory/hosts playbooks/setup-monitoring.yml
```

### Step 4: Test Locally with Docker Compose
```bash
cd docker
docker-compose up -d
# API:      http://localhost:5000
# Frontend: http://localhost:3000
```

### Step 5: Deploy to Kubernetes
```bash
ssh -i ~/.ssh/devops-key.pem ubuntu@<K8S_MASTER_IP>
kubectl apply -f kubernetes/
kubectl get pods -n devops-app
```

### Step 6: Setup Jenkins Pipeline
1. Open `http://<JENKINS_IP>:8080`
2. Install plugins: SonarQube Scanner, Docker Pipeline, SSH Agent
3. Add credentials: Docker Hub (username/password), K8s Master SSH key
4. Create Pipeline job — point to `Jenkinsfile` in your Git repo

## Monitoring

| Service        | URL                              | Credentials     |
|----------------|----------------------------------|-----------------|
| Jenkins        | `http://<JENKINS_IP>:8080`       | Initial from setup |
| SonarQube      | `http://<JENKINS_IP>:9000`       | admin / admin   |
| Prometheus     | `http://<K8S_MASTER_IP>:9090`    | —               |
| Grafana        | `http://<K8S_MASTER_IP>:3000`    | admin / admin123|

## Key Features

- **3 EC2 instances** — Jenkins+SonarQube, K8s Master, K8s Worker
- **CI/CD pipeline** — 6-stage Jenkins pipeline with quality gates
- **Security scanning** — Trivy vulnerability scanning on every build
- **Self-managed K8s** — kubeadm cluster with Flannel CNI
- **Auto-scaling** — HPA scales pods at 70% CPU
- **Zero-downtime** — Rolling updates with liveness/readiness probes
- **Monitoring** — Prometheus + Grafana + Alertmanager
- **IaC** — Full infrastructure defined in Terraform
- **Automation** — Ansible playbooks for complete server setup
