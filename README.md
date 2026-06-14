# idp-platform

A production-grade **Internal Developer Platform** built on Kubernetes, the way
real platform teams build them: **one Git repo is the source of truth, and Argo
CD makes the cluster match it.** Nothing is clicked by hand.

This repo is a learning-by-building project. It starts as an empty local cluster
and grows, one phase at a time, into a platform with ingress + TLS, real secrets
management, observability, progressive delivery, and software-supply-chain
security — each piece added the GitOps way.

> Runs **free** on a local [kind](https://kind.sigs.k8s.io/) cluster. The layout
> is kept clean so a cloud (EKS) module can be slotted in later without changing
> how the platform itself is managed.

---

## How it works

```
            you commit to Git
                   │
                   ▼
        ┌──────────────────────┐        watches platform/ and apps/
        │     this Git repo     │◀──────────────────────────────┐
        └──────────────────────┘                                │
                   │  applied once (the only manual step)        │
                   ▼                                             │
        ┌──────────────────────┐    syncs desired state    ┌──────────┐
        │  bootstrap/argocd     │──────────────────────────▶│ Argo CD  │
        │  (root app-of-apps)   │                           └────┬─────┘
        └──────────────────────┘                                │
                                                                 ▼
                                                    ┌────────────────────────┐
                                                    │   kind Kubernetes       │
                                                    │   cluster (local)       │
                                                    └────────────────────────┘
```

You apply the **root app-of-apps** exactly once. After that, the only way to
change the cluster is to commit to this repo — Argo CD does the rest and reverts
any manual drift.

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (running)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

`make preflight` checks all of these for you.

## Quickstart

```bash
make up            # create kind cluster + install Argo CD + apply root app
make argocd-password   # print the initial admin password
make argocd-ui         # open the UI at https://localhost:8080  (user: admin)
```

Tear it all down with `make down`. Run `make` with no arguments for the full
list of targets.

---

## Repository layout

```
idp-platform/
├── Makefile                 # the control plane for your laptop
├── clusters/local/          # kind cluster definition
├── bootstrap/argocd/        # the one-time seed: Argo CD root app-of-apps
├── platform/                # platform components (Argo CD manages these)  ← grows each phase
├── apps/                    # your actual workloads (also GitOps-managed)
└── docs/                    # the phase-by-phase roadmap
```

---

## Roadmap

| Phase | What you build | Status |
|------:|----------------|:------:|
| 1 | Local kind cluster, reproducible from one config | ✅ |
| 2 | Argo CD installed + app-of-apps bootstrap (GitOps backbone) | ✅ |
| 3 | ingress-nginx + cert-manager (real TLS) | ✅ |
| 4 | Secrets management (External Secrets / Vault) | ⬜ |
| 5 | Observability (Prometheus + Grafana + Loki, SLOs) | ⬜ |
| 6 | Progressive delivery (Argo Rollouts, canary + auto-rollback) | ⬜ |
| 7 | Supply-chain security (Trivy, cosign, SBOMs, Kyverno) | ⬜ |
| 8 | CI that builds → scans → signs → updates this repo | ⬜ |

Details and the "why" behind each phase live in [`docs/roadmap.md`](docs/roadmap.md).

---

## What you'll actually learn

Not "how to run a tool" — how the pieces **fit together**: declarative cluster
management, the app-of-apps pattern, drift detection and self-heal, ingress and
TLS the correct way, secrets without plaintext in Git, SLO-based observability,
safe progressive rollouts, and supply-chain security. The integration is the
lesson.
