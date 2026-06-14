# platform/

This directory is the **desired state** of the platform. Argo CD's root
`platform` Application (see [`../bootstrap/argocd/root-app.yaml`](../bootstrap/argocd/root-app.yaml))
watches this folder and syncs anything it finds here into the cluster.

It is intentionally empty right now — that's Phase 2 done. From Phase 3 on, each
platform component lands here as its own Argo CD `Application` manifest:

| Phase | Component | File (future) |
|------:|-----------|---------------|
| 3 | ingress-nginx + cert-manager | `ingress-nginx.yaml`, `cert-manager.yaml` |
| 4 | External Secrets / Vault | `external-secrets.yaml` |
| 5 | kube-prometheus-stack + Loki | `monitoring.yaml` |
| 6 | Argo Rollouts | `argo-rollouts.yaml` |
| 7 | Trivy Operator + Kyverno | `security.yaml` |

**The rule:** to change the cluster, you change a file here and commit. You do
not `kubectl apply` by hand. That discipline is the whole point of GitOps.
