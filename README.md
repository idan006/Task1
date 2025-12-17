# My App – DevOps, DevSecOps & GitOps Demo

This repository demonstrates a **production-grade DevOps, DevSecOps, and GitOps workflow** for a stateless Node.js application deployed to Kubernetes.

It is designed to be:
- Fully reproducible
- Secure by default
- GitOps-driven
- Verifiable end-to-end

---

## System Architecture

```mermaid
flowchart LR
    Dev[Developer]

    Dev -->|Code Push| GitHub[(GitHub Repository)]

    GitHub -->|Trigger| CI[GitHub Actions CI/CD]

    CI -->|Bootstrap| Prereq[prerequisites.sh]
    CI -->|SAST| Semgrep[Semgrep]
    CI -->|Build Image| DockerBuild[Docker Build]
    CI -->|Scan Image| Trivy[Trivy]

    DockerBuild --> DockerHub[(Docker Hub)]
    Trivy -->|Pass| DockerHub

    CI -->|Update Helm values| GitHub

    GitHub -->|Watched by| ArgoCD[ArgoCD]

    ArgoCD -->|Deploy Helm Chart| K8s[(Kubernetes Cluster)]

    K8s --> Service[Service]
    Service --> Ingress[Ingress]
    Ingress --> User[User / Client]


---

## Project Checklist

### Helm & Kubernetes
- [x] Helm chart with Deployment, Service, Ingress
- [x] Correct use of Deployment (stateless app)
- [x] Readiness and liveness probes
- [x] CPU and memory requests & limits
- [x] ConfigMap for externalized configuration

### CI/CD & DevSecOps
- [x] GitHub Actions CI/CD pipeline
- [x] Trunk-based development workflow
- [x] Numeric build/version IDs
- [x] SAST using Semgrep (blocking)
- [x] Image vulnerability scanning using Trivy (blocking)

### Docker & Registry
- [x] Plain Docker build
- [x] Dockerfile included
- [x] Image pushed to Docker Hub (`idan006/idanhub`)

### GitOps & Deployment
- [x] ArgoCD Application manifest
- [x] Declarative deployment via Helm
- [x] GitOps model clearly explained
- [x] CI updates Git, ArgoCD deploys

### Developer Experience
- [x] Shared bootstrap script (`prerequisites.sh`)
- [x] Deterministic local deploy (`task deploy`)
- [x] Deterministic verification (`task verify`)
- [x] Full cleanup (`task cleanup`)
