# netdata Helm chart for kubernetes deployments

_Based on the work of varyumin (https://github.com/varyumin/netdata)_

**This Helm chart is in Beta**. 
Please validate that the settings are suitable for your cluster, before using 
them in production 

## Introduction

This chart bootstraps a [netdata](https://github.com/netdata/netdata) deployment 
on a  [Kubernetes](http://kubernetes.io) cluster using the 
[Helm](https://helm.sh) package manager.

The chart installs a netdata slave pod on each node of a cluster, using a 
`Daemonset` and a netdata master pod on one node, using a `Statefulset`. The 
slaves function as headless collectors that simply collect and forward all the 
metrics to the master netdata. The master uses persistent volumes to store 
metrics and alarms, handles alarm notifications and provides the netdata UI to 
view the metrics, using an nginx ingress controller.

## Prerequisites
  - Kubernetes 1.8+

## Installing the Chart

Clone the repository locally

```console
$ git clone https://github.com/netdata/helmchart.git netdata
```

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release ./netdata
```

The command deploys nginx-ingress on the Kubernetes cluster in the default 
configuration. The [configuration](#configuration) section lists the parameters 
that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and 
deletes the release.

## Configuration

The following table lists the configurable parameters of the nginx-ingress 
chart and their default values.

Parameter | Description | Default
--- | --- | ---
`replicaCount` | Number of `replicas` for the master netdata `Statefulset` | `1`
`image.repository` | Container image repo | `netdata/netdata`
`image.tag` | Container image tag | `TBD`
`image.pullPolicy` | Container image pull policy | `Always`
`service.type` | netdata master service type | `ClusterIP`
`service.port` | netdata master service port | `19999`
`ingress.enabled` | Create Ingress to access the netdata web UI | `true`
`ingress.annotations` | Associate annotations to the Ingress | ```yaml
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
```
`ingress.path` | URL path for the ingress | `/`
`ingress.port` | URL port for the ingress | `80`
`hosts` | URL hostnames for the ingress (they need to resolve to the external IP of the ingress controller) | `netdata.k8s.local`
`serviceaccount.name` | Name of the service account that provides access rights  to netdata | `netdata`
`clusterrole.name` | Name of the cluster role linked with the service account | `netdata`
`master.resources` | Resources for the master statefulset | `{}`
`master.nodeSelector` | Node selector for the master statefulset | `{}`
`master.tolerations` | Tolerations settings for the master statefulset | `[]`
`master.affinity` | Affinity settings for the master statefulset | `{}`
`master.database.storageclass` | The storage class for the persistent volume claim of the master's database store, mounted to `/var/cache/netdata` | `standard`
`master.database.volumesize` | The storage space for the PVC of the master database | `2Gi`
`master.alarms.storageclass` | The storage class for the persistent volume claim of the master's alarm log, mounted to `/var/lib/netdata` | `standard`
`master.database.volumesize` | The storage space for the PVC of the master alarm log | `100Mi`
`slave.resources` | Resources for the slave daemonsets | `{}`
`slave.nodeSelector` | Node selector for the slave daemonsets | `{}`
`slave.tolerations` | Tolerations settings for the slave daemonsets | ```yaml
- operator: Exists
      effect: NoSchedule
```
`slave.affinity` | Affinity settings for the slave daemonsets | `{}`
`notifications.slackurl` | URL for slack notifications | `""`
`notifications.slackrecipient` | Slack recipient list | `""`

Example to set the parameters from the command line:
```console
$ helm install ./netdata --name my-release \
    --set notifications.slackurl=MySlackAPIURL \
    --set notifications.slackrecipiet="@MyUser MyChannel"
```

Alternatively, a YAML file that specifies the values for the parameters can be 
provided while installing the chart. For example,

```console
$ helm install ./netdata --name my-release -f values.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)

