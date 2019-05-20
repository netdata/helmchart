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
`image.tag` | Container image tag | `v1.12.2`
`image.pullPolicy` | Container image pull policy | `Always`
`service.type` | netdata master service type | `ClusterIP`
`service.port` | netdata master service port | `19999`
`ingress.enabled` | Create Ingress to access the netdata web UI | `true`
`ingress.annotations` | Associate annotations to the Ingress | `kubernetes.io/ingress.class: nginx` and `kubernetes.io/tls-acme: "true"`
`ingress.path` | URL path for the ingress | `/`
`ingress.hosts` | URL hostnames for the ingress (they need to resolve to the external IP of the ingress controller) | `netdata.k8s.local`
`rbac.create` | if true, create & use RBAC resources | `true`
`serviceAccount.create` |if true, create a service account | `true`
`serviceAccount.name` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. | `netdata`
`clusterrole.name` | Name of the cluster role linked with the service account | `netdata`
`APIKEY` | The key shared between the master and the slave netdata for streaming | `11111111-2222-3333-4444-555555555555`
`master.resources` | Resources for the master statefulset | `{}`
`master.nodeSelector` | Node selector for the master statefulset | `{}`
`master.tolerations` | Tolerations settings for the master statefulset | `[]`
`master.affinity` | Affinity settings for the master statefulset | `{}`
`master.database.storageclass` | The storage class for the persistent volume claim of the master's database store, mounted to `/var/cache/netdata` | `standard`
`master.database.volumesize` | The storage space for the PVC of the master database | `2Gi`
`master.alarms.storageclass` | The storage class for the persistent volume claim of the master's alarm log, mounted to `/var/lib/netdata` | `standard`
`master.alarms.volumesize` | The storage space for the PVC of the master alarm log | `100Mi`
`master.env` | Set environment parameters for the master statefulset | `{}`
`master.stream_config` | Contents of the master's `stream.conf` | Store slave data, accept all connections, and issue alarms for slave data.
`master.netdata_config` | Contents of the master's `netdata.conf` | `memory mode = save` and `bind to = 0.0.0.0:19999`
`master.health_config` | Contents of `health_alarm_notify.conf` | Email disabled, a sample of the required settings for Slack notifications
`slave.resources` | Resources for the slave daemonsets | `{}`
`slave.nodeSelector` | Node selector for the slave daemonsets | `{}`
`slave.tolerations` | Tolerations settings for the slave daemonsets | `- operator: Exists` with `effect: NoSchedule`
`slave.affinity` | Affinity settings for the slave daemonsets | `{}`
`slave.env` | Set environment parameters for the slave daemonset | `{}`
`slave.stream_config` | Contents of the slave `stream.conf` | Send metrics to the master at netdata:19999
`slave.netdata_config` | Contents of the slave's `netdata.conf` | No persistent storage, no alarms, no UI
`slave.coredns_config` | Contents of the slave's `go.d/coredns.conf` that drives the coredns collector | Update metrics every sec, do not retry to detect the endpoint, look for the coredns metrics at http://127.0.0.1:9153/metrics
`slave.kubelet_config` | Contents of the slave's `go.d/k8s_kubelet.conf` that drives the kubelet collector | Update metrics every sec, do not retry to detect the endpoint, look for the kubelet metrics at http://127.0.0.1:10255/metrics
`slave.kubeproxy_config` | Contents of the slave's `go.d/k8s_kubeproxy.conf` that drives the kubeproxy collector | Update metrics every sec, do not retry to detect the endpoint, look for the coredns metrics at http://127.0.0.1:10249/metrics
`notifications.slackurl` | URL for slack notifications | `""`
`notifications.slackrecipient` | Slack recipient list | `""`
`sysctlImage.enabled` | Enable an init container to modify Kernel settings | `false` |
`sysctlImage.command` | sysctlImage command to execute | [] |
`sysctlImage.repository`| sysctlImage Init container name | `alpine` |
`sysctlImage.tag` | sysctlImage Init container tag | `latest` |
`sysctlImage.pullPolicy` | sysctlImage Init container pull policy | `Always` |
`sysctlImage.resources` | sysctlImage Init container CPU/Memory resource requests/limits | {} |

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

### Additional netdata configurations

To deploy additional netdata user configuration files, you will need to modify the helm chart configuration files as explained below. 

#### Adding a configuration file to the master

To provide a new user configuration file to the master, you need to edit the following:
 - In `templates/statefulset.yaml` : `spec.template.spec.volumes` and `spec.template.spec.containers.volumeMounts`.
 - In `templates/configmap.yaml` : In the second `ConfigMap` with `metadata.name=netdata-conf-master`, update `metadata.data`.

Note that with the default configuration of this chart, the master does the health checks and triggers alarms, but does not collect much data. As a result, the only other 
configuration files that might make sense to add are the alarm and alarm template definitions, under `/etc/netdata/health.d`. 

#### Adding a configuration file to the slaves

To provide a new user configuration file to the slave pods, you need to edit the following:
 - In `templates/daemonset.yaml` : `spec.template.spec.volumes` and `spec.template.spec.containers.volumeMounts`.
 - In `templates/configmap.yaml` : In the first `ConfigMap` with `metadata.name=netdata-conf-slave`, update `metadata.data`.
 
Regardless of whether you add config files that reside directly under `/etc/netdata` or in a subdirectory 
such as `/etc/netdata/go.d`, you can use the already provided configurations as reference. 

#### Example

For reference, the `yaml` templates of the master mentioned above include an `example` alarm that would get triggered if the python.d `example` module was enabled. 
You will see in this case that we chose not to add a value for the contents of the configuration file in `values.yaml`. We use the multi-line syntax `var: |-` and enter 
the contents of the config file underneath. 

> **Tip**: Do pay attention to the indentation of the config file contents, as it matters for the parsing of the `yaml` file. Note that the first line under `var: |-` 
must be indented with two more spaces relative to the preceding line:

```
  myconfigfilecontents: |-
    config line 1 #Need those two spaces
        config line 2 #No problem indenting more here
```
