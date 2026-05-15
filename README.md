## Architecture Overview

A React frontend and Node.js backend deployed on AWS ECS Fargate,
behind an Application Load Balancer, with a Jenkins CI/CD pipeline
for automated deployments.Internet → ALB (public) → Frontend ECS Service (private subnet)
→ Backend ECS Service (private subnet) [/api/*]

## Tech Stack

- **Frontend:** React, served via `serve` as static build
- **Backend:** Node.js
- **Containerization:** Docker
- **Registry:** AWS ECR
- **Orchestration:** AWS ECS Fargate
- **Infrastructure:** Terraform
- **CI/CD:** Jenkins (pipeline as code)
- **Networking:** VPC with public/private subnets across 2 AZs
- **Load Balancing:** AWS ALB with path-based routing
- **Auto Scaling:** Target tracking on CPU utilization (threshold: 50%)

## Prerequisites

- Docker Desktop
- AWS CLI configured (`aws configure`)
- Terraform
- Node.js & npm
- An AWS account with an IAM user with appropriate permissions
- A GitHub account with SSH configured

## Phase 1 — Local Setup

```bashgit clone https://github.com/TayoLusi19/devops-code-challenge1.git
cd devops-code-challenge1Backend
cd backend && npm ci && npm start
Verify at http://localhost:8080Frontend (new terminal)
cd frontend && npm ci && npm start
Verify at http://localhost:3000 — should show SUCCESS + GUID

## Phase 2 — Docker

```bashBuild images
docker build -t backend-app ./backend
docker build -t frontend-app ./frontendRun containers
docker run -d --name backend -p 8080:8080 backend-app
docker run -d --name frontend -p 3000:3000 frontend-appVerify at http://localhost:3000

## Phase 3 — Infrastructure (Terraform)

```bashcd terraform
terraform init
terraform plan
terraform apply

### Key infrastructure decisions:
- ECS tasks run in **private subnets** — unreachable from internet directly
- Only the ALB lives in **public subnets** — single internet entry point
- **Security group chaining** — frontend only accepts traffic from ALB SG,
  backend only accepts traffic from frontend SG and ALB SG
- **Fargate** over EC2 — no server management, pay per task
- **NAT Gateway** — allows private subnet tasks to pull ECR images
  and call AWS APIs without being publicly exposed
- **Two availability zones** — high availability, survives single AZ outage

## Phase 4 — Jenkins Setup

Jenkins runs as a Docker container on an EC2 instance provisioned by Terraform.

```bashSSH into Jenkins EC2
ssh -i "your-key.pem" ec2-user@<jenkins-public-ip>Run Jenkins container
docker run -d 
--name jenkins 
-p 8080:8080 
-v /var/jenkins_home:/var/jenkins_home 
-v /var/run/docker.sock:/var/run/docker.sock 
--group-add <docker-group-id> 
jenkins/jenkins:lts

Access Jenkins at `http://<jenkins-ec2-ip>:8080`

Required credentials stored in Jenkins (never in code):
- GitHub PAT (Username/Password kind)
- AWS credentials (AWS Credentials kind)

## Phase 5 — CI/CD Pipeline

Pipeline stages (defined in `Jenkinsfile`):
1. **Checkout** — pulls latest code from GitHub
2. **Build** — builds Docker images for frontend and backend
3. **Authenticate** — gets temporary ECR token via AWS CLI
4. **Push** — tags and pushes images to ECR
5. **Deploy** — forces new ECS deployment with updated images

Triggered automatically via GitHub webhook on every push to `main`.

## Phase 6 — Validation

After pipeline runs:
- Verify images exist in ECR with recent timestamp
- Verify ECS tasks are in RUNNING state
- Verify ALB target groups show healthy targets
- Visit ALB DNS — should display SUCCESS + GUID

## Phase 7 — Load Testing & Auto Scaling Results

```bashsiege -c 250 -t 2M http://<alb-dns>

### Results:
| Metric | Value |
|--------|-------|
| Availability | XX% |
| Transaction rate | XX req/sec |
| Response time | XX sec |
| Tasks at peak | X |

### Scaling behavior:
- At ~90 seconds CPU exceeded 50% threshold
- ECS scaled from 1 → X tasks
- After load stopped, scaled back to 1 task over ~15 minutes
- Scale-in uses cooldown period to prevent task thrashing

## Cleanup

To avoid ongoing AWS charges:

```bashcd terraform
terraform destroy
Fill in your actual siege numbers in the results table — specific numbers from your actual test carry far more weight than placeholders.