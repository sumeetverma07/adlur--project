# AWS Docker Deployment Platform (Assignment Submission)

This repository is an **AWS-focused, defendable subset** of the Senior DevOps assignment. It provisions the infrastructure I know and can explain: VPC networking, public/private/database subnets, routing, security groups, an internet-facing Application Load Balancer, an EC2 Auto Scaling Group running Docker, Amazon RDS PostgreSQL, and Amazon ElastiCache Redis.

> The assignment asks for a cloud-agnostic Kubernetes platform. This submission does not pretend that EC2 Auto Scaling is Kubernetes or cloud-agnostic. The AWS implementation is the working target; Kubernetes, multi-cloud, canary delivery, fleet rollout, and advanced operations are documented as the next 90-day phase.

## What is included

| Area | Status | Notes |
|---|---|---|
| AWS network (2 AZs) | Implemented in Terraform | 2 public, 2 private application, 2 private database subnets |
| IGW, NAT Gateway, route tables | Implemented | One NAT Gateway keeps the demo affordable; production should use one per AZ |
| ALB and security groups | Implemented | Internet -> ALB on 80; ALB -> application on 8080 only |
| EC2 Auto Scaling + Docker | Implemented | Launch template installs Docker and runs an immutable image reference |
| RDS PostgreSQL | Implemented | Private DB subnet group, encryption, Multi-AZ option, Secrets Manager password |
| ElastiCache Redis | Implemented | Private application subnets; TLS in transit and encryption at rest |
| Build/scan/push pipeline | Implemented as GitHub Actions | Builds once, scans with Trivy, pushes to ECR, deploys by digest |
| Health checks and rolling refresh | Implemented | ALB checks `/healthz`; ASG instance refresh uses minimum healthy percentage |
| Kubernetes / second target | Design only | Proposed in [docs/architecture.md](docs/architecture.md) |
| Metric-gated canary / GitOps | Design only | Proposed migration path; not represented as completed evidence |
| Load, rollback, restore evidence | Scripts/checklists only | Must be run in the candidate's AWS account before claiming evidence |

## Architecture

```text
Internet
   |
Internet Gateway
   |
ALB (public subnet A + public subnet B)
   |
EC2 Auto Scaling Group (private app subnet A + B, Docker, port 8080)
   |                         |
RDS PostgreSQL               ElastiCache Redis
(private DB subnets)         (private app subnets)
   |
NAT Gateway in public A supplies outbound access for private instances
```

The submission-ready deliverable is [docs/architecture.pdf](docs/architecture.pdf) (exactly five A4 pages). Its editable sources are [docs/architecture.html](docs/architecture.html) and [docs/architecture.md](docs/architecture.md). It includes the diagram, seven decisions with rejected alternatives, exactly five top risks, scaling maths, SLOs, tenant design, cost controls, and roadmap.

## Prerequisites

- Terraform >= 1.6
- AWS CLI authenticated to a sandbox AWS account
- An existing ECR repository and a compatible application image exposing port `8080` with `/healthz`
- The black-box application source and its `Dockerfile` at repository root if using the included build workflow (the assignment did not supply them)
- A remote Terraform state S3 bucket and DynamoDB lock table (bootstrap example below)

## Deploy

No AWS console steps are required after prerequisites and credentials are available.

```bash
cd infra/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars, especially image_uri and allowed_admin_cidrs.
terraform init \
  -backend-config="bucket=YOUR_STATE_BUCKET" \
  -backend-config="key=dev/platform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=YOUR_LOCK_TABLE" \
  -backend-config="encrypt=true"
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

After apply:

```bash
curl "http://$(terraform output -raw alb_dns_name)/healthz"
```

## Safe image release

The workflow in `.github/workflows/build-deploy.yml` first checks whether the assignment's black-box application and root `Dockerfile` are present. Because they were not supplied, infrastructure-only pushes pass with a notice and safely skip image/AWS deployment steps. Once the real application is added, the workflow builds and scans one image, pushes it to ECR, resolves the digest, and applies that exact digest through Terraform. An ASG instance refresh gradually replaces instances while the ALB keeps traffic on healthy instances. Set these GitHub environment secrets/variables before adding/running the application build:

- Secrets: `AWS_ROLE_ARN`, `TF_STATE_BUCKET`, `TF_LOCK_TABLE`
- Variables: `AWS_REGION`, `ECR_REPOSITORY`

Production should add manual approval on the GitHub `production` environment. This pipeline is rolling deployment, not a true metric-gated canary.

## Evidence and honesty checklist

Run and save outputs under `evidence/` before submitting:

1. `terraform plan` and `terraform apply` logs.
2. A health check and deployment under load with zero non-2xx responses.
3. A deliberately unhealthy image demonstrating ALB rejection/ASG rollback.
4. A 15x load test with CloudWatch screenshots/exports.
5. An RDS restore test into a separate temporary database.

Do not label any of these as passed until actually run. The repository contains no fabricated logs.

## Known gaps against the full brief

- AWS-specific resources are not cloud-agnostic and there is no second provider implementation.
- EC2 Auto Scaling is used instead of Kubernetes; there are no Kubernetes probes, PDBs, HPA/KEDA, or GitOps controller.
- Worker deployment and queue-depth autoscaling require application image/command details that were not supplied.
- Database migrations are controlled by application startup, so expand/contract safety cannot be guaranteed by infrastructure alone.
- Dedicated tenant fleet automation, EU/US policy enforcement, automated restore tests, signing, and SLO-based rollout gates remain roadmap items.

These limitations are deliberate: this project demonstrates real knowledge instead of claiming technologies that were not implemented or tested.
