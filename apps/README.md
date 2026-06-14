# apps/

Your actual workloads live here — the things the *platform* exists to run.

In a later phase we deploy a small sample service through the full pipeline:
built in CI, scanned, signed, exposed via ingress with a real TLS cert, watched
by the monitoring stack, and rolled out progressively (canary) with automatic
rollback on bad metrics.

Like `platform/`, everything here is GitOps-managed: an Argo CD Application
points at this directory, so a `git push` is the only deploy step.
