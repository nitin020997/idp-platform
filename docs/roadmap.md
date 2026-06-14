# Roadmap

The platform is built in phases. Each phase is independently useful — you can
stop at any point and still have something real and demoable — and each one
teaches a distinct, marketable skill. The rule throughout: **after Phase 2,
everything is added by committing to `platform/`, never by hand.**

---

## Phase 1 — Local cluster ✅

A reproducible Kubernetes cluster from a single config file.

- `clusters/local/kind-config.yaml` — one control-plane (labelled
  `ingress-ready=true`) + one worker, with host ports 80/443 mapped so ingress
  works later.
- `make cluster-up` / `make cluster-down`.

**You learn:** how a cluster is defined as code; node roles; why ingress needs
host-port mapping on kind.

## Phase 2 — GitOps backbone ✅

Argo CD installed, then handed control of the repo via the app-of-apps pattern.

- `make argocd-install` installs Argo CD.
- `bootstrap/argocd/root-app.yaml` is the single seed you apply by hand. It
  points Argo CD at `platform/`, so from now on Git is the source of truth.
- `automated.prune` + `selfHeal` mean Argo CD deletes what you remove from Git
  and reverts manual `kubectl` changes.

**You learn:** declarative cluster management, the app-of-apps pattern, drift
detection and self-heal.

---

## Phase 3 — Ingress + TLS ✅

ingress-nginx for routing, cert-manager for automatic certificates. Locally we
issue certs with a self-signed `ClusterIssuer`; the same Ingress annotations use
Let's Encrypt against a real domain on a cloud cluster.

Added the GitOps way as child apps under `platform/` (`ingress-nginx.yaml`,
`cert-manager.yaml`, `cluster-issuer.yaml`) plus an `apps` Application that
GitOps-manages `apps/`. The `whoami` demo (`apps/demo/`) proves it end to end:
reachable at `https://whoami.localhost` with a cert-manager-issued certificate.

**You learn:** Kubernetes networking, Ingress resources, TLS, cert lifecycle,
the ingress-shim annotation flow, and extending app-of-apps to workloads.

## Phase 4 — Secrets management ✅

No plaintext secrets in Git. External Secrets Operator (ESO) pulls from a Vault
backend (dev mode locally) and materializes native Kubernetes Secrets.

Added GitOps-style: `external-secrets.yaml` + `vault.yaml` (controllers),
`vault-secret-store.yaml` (a `ClusterSecretStore`), and
`apps/demo/whoami-externalsecret.yaml` (an `ExternalSecret`). Git holds only
*references* — the real values live in Vault. The one credential (Vault token)
is created out-of-band, never committed; production would use Vault's Kubernetes
auth instead. Verified live: rotating `secret/whoami` in Vault auto-synced into
the cluster Secret within the refresh interval, no redeploy.

**You learn:** the SecretStore/ExternalSecret model, secret rotation/refresh,
the SealedSecrets vs. External Secrets vs. Vault trade-offs, keeping Git safe to
be public.

## Phase 5 — Observability ⬜

kube-prometheus-stack (Prometheus + Grafana + Alertmanager) and Loki for logs.
Then define **SLOs and error budgets** for the sample app and alert on burn rate.

**You learn:** the metrics/logs/traces split, PromQL, SLO-based alerting — the
stuff on-call actually uses.

## Phase 6 — Progressive delivery ⬜

Argo Rollouts for canary / blue-green deploys, with **automated rollback** when
the Phase 5 metrics say the new version is bad.

**You learn:** safe deploys, analysis templates, the hard half of CD.

## Phase 7 — Supply-chain security ⬜

Image scanning (Trivy Operator), image signing (cosign), SBOM generation, and
admission policies (Kyverno) that block unsigned or critical-CVE images.

**You learn:** the security layer everyone is hiring for — provenance, signing,
admission control.

## Phase 8 — CI ⬜

GitHub Actions that build the app image, test it, scan it, sign it, and then
**update this repo** (image tag bump) so Argo CD deploys it. Closes the loop
between CI (build) and CD (deploy).

**You learn:** how CI and CD actually hand off in a GitOps world.
