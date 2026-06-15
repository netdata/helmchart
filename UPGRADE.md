# Upgrade Notes

## 3.7.166

### Parent database default volume size increased to 15Gi

The default value of `parent.database.volumesize` has been increased from `5Gi` to `15Gi`.

This change better reflects the storage requirements of a Netdata parent node across a wider range of real-world deployments.

**Who is affected**

Only users who rely on the default value — i.e., who have not explicitly set `parent.database.volumesize` in their own `values.yaml` or `--set` flags.

**Potential upgrade failure**

If your cluster's StorageClass does not have `allowVolumeExpansion: true`, `helm upgrade` will fail with an error similar to:

```
PersistentVolumeClaims "netdata-parent-database" is forbidden: only dynamically provisioned
pvc can be resized and the storageclass that provisions the pvc must support resize
```

**How to avoid this**

Pin the volume size to your current value to prevent any resize attempt:

```yaml
parent:
  database:
    volumesize: 5Gi
```

Or, if you want to expand but your StorageClass does not support automatic expansion, manually resize the PVC before running `helm upgrade`:

```bash
kubectl patch pvc netdata-parent-database -p '{"spec":{"resources":{"requests":{"storage":"15Gi"}}}}'
```

Note that manual resizing also requires the StorageClass to support volume expansion. On clusters where expansion is not supported at all, keep the old value pinned in your values.
