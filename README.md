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
