# netdata Helm chart for kubernetes deployments

_Based on the work of varyumin (https://github.com/varyumin/netdata)_

**This Helm chart is in Beta**. 
Please validate that the settings are suitable for your cluster, before using 
them in production 

## Introduction



## Helm Chart `netdata`
Each **netdata** `(slave)` is able to replicate/mirror its database to another 
**netdata** `(master)`, by streaming collected
metrics, in real-time to it.

### netdata `(slave)`
**netdata** is installed as DaemonSet.

### netdata `(master)` 
**netdata** is installed as StatefulSet. It makes persistent volume claims with 
class "standard" to store the metrics database and the alarms

The slaves are headless collectors, sending their metrics to the master. 

### netdata configuration

`templates/configmap.yaml` contains minimal master and slave configurations for 
netdata.conf, stream.conf and health_alarm_notify.conf. 



## Introduction

This chart bootstraps an nginx-ingress deployment on a 
[Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) 
package manager.

## Prerequisites
  - Kubernetes 1.6+

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release stable/nginx-ingress
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
`replicaCount` | number of `replicas` for the master netdata `Statefulset` | 
`1`
`image.repository` | container image repo | `netdata/netdata`
`image.tag` | container image tag | `TBD`
`image.pullPolicy` | container image pull policy | `Always`
`service.type` | netdata master service type | `ClusterIP`
`service.port` | netdata master service port | `19999`
`ingress.enabled` | whether to use an ingress controller to access the UI | 
`true`
`ingress.annotations.kubernetes.io/ingress.class` | ingress controller to use | 
`nginx`
`ingress.annotations.kubernetes.io/tls-acme`


```console
$ helm install stable/nginx-ingress --name my-release \
    --set controller.stats.enabled=true
```

Alternatively, a YAML file that specifies the values for the parameters can be 
provided while installing the chart. For example,

```console
$ helm install stable/nginx-ingress --name my-release -f values.yaml
```

A useful trick to debug issues with ingress is to increase the logLevel
as described 
[here](https://github.com/kubernetes/ingress-nginx/blob/master/docs/troubleshooting.md#debug)

```console
$ helm install stable/nginx-ingress --set controller.extraArgs.v=2
```
> **Tip**: You can use the default [values.yaml](values.yaml)

