# Runbook: Node Not Ready

Linked alert: `KubeNodeNotReady`

## Quick checks

```bash
kubectl get nodes -o wide
kubectl describe node <node>
kubectl get events --sort-by=.lastTimestamp | tail -50
```

## Common causes

| Symptom | Cause | Action |
| --- | --- | --- |
| `kubelet stopped posting node status` | kubelet crashed | Check the cloud's serial console; reboot via cloud API. |
| Networking is degraded | CNI restart loop | `kubectl -n kube-system logs ds/aws-node` (or `cilium`). |
| Disk pressure | `/var` filling | Drain the node and let the autoscaler replace it. |
| Memory pressure | Misbehaving pod | Drain; identify and cap the offender. |

## Drain & replace

```bash
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --force --grace-period=120
# Cluster autoscaler will replace it; for AWS:
aws ec2 terminate-instances --instance-ids <id>
```

## When more than one node is NotReady

Page the platform on-call and consider the underlying control plane. Don't drain en masse.
