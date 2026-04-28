# Runbook: PVC almost full

Linked alert: `PvcAlmostFull` (used / capacity > 0.85 for 15 min)

## Auto-remediation

The `pvc-resizer` CronJob in the `self-healing` namespace runs every 10 minutes. For PVCs whose StorageClass has `allowVolumeExpansion: true`, it patches `spec.resources.requests.storage` upward by 1.5×. You will usually find the alert auto-resolved before you act.

Audit log:

```bash
kubectl -n self-healing logs cronjob/pvc-resizer --tail=200
```

## When auto-remediation is not available

If the StorageClass does not support expansion, the resizer logs `skip: storage class not expandable`. In that case:

1. Take a snapshot of the PVC.
2. Provision a larger PVC backed by an expandable class.
3. Restore data.
4. Update the workload's volume claim template to point at the new class.

## Prevention

- Always pick an expandable StorageClass for stateful workloads (gp3, premium-rwo, managed-csi). Codify in [docs/adr/0004-storage-classes.md](../adr/0004-storage-classes.md).
- Don't hand-mount static PVs except for read-only datasets.
