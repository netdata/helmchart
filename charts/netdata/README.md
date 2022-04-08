# Netdata Helm chart for Kubernetes deployments

[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/netdata)](https://artifacthub.io/packages/search?repo=netdata) ![Version: 3.7.14](https://img.shields.io/badge/Version-3.7.14-informational) ![AppVersion: v1.33.1](https://img.shields.io/badge/AppVersion-v1.33.1-informational)

_Based on the work of varyumin (https://github.com/varyumin/netdata)_.

## Introduction

This chart bootstraps a [Netdata](https://github.com/netdata/netdata) deployment on a [Kubernetes](http://kubernetes.io)
cluster using the [Helm](https://helm.sh) package manager.

The chart installs a Netdata child pod on each node of a cluster, using a `Daemonset` if not disabled, and a Netdata
parent pod on one node, using a `Deployment`. The child pods function as headless collectors that collect and forward
all the metrics to the parent pod. The parent pod uses persistent volumes to store metrics and alarms, handle alarm
notifications, and provide the Netdata UI to view metrics using an ingress controller.

Please validate that the settings are suitable for your cluster before using them in production.

## Prerequisites

- A working cluster running Kubernetes v1.9 or newer.
- The [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) command line tool,
  within [one minor version difference](https://kubernetes.io/docs/tasks/tools/install-kubectl/#before-you-begin) of
  your cluster, on an administrative system.
- The [Helm package manager](https://helm.sh/) v3.0.0 or newer on the same administrative system.

## Installing the Helm chart

You can install the Helm chart via our Helm repository, or by cloning this repository.

### Installing via our Helm repository (recommended)

To use Netdata's Helm repository, run the following commands:

```bash
helm repo add netdata https://netdata.github.io/helmchart/
helm install netdata netdata/netdata
```

**See our [install Netdata on Kubernetes](https://learn.netdata.cloud/docs/agent/packaging/installer/methods/kubernetes)
documentation for detailed installation and configuration instructions.** The remainder of this document assumes you
installed the Helm chart by cloning this repository, and thus uses slightly different `helm install`/`helm upgrade`
commands.

### Install by cloning the repository

Clone the repository locally.

```console
git clone https://github.com/netdata/helmchart.git netdata-helmchart
```

To install the chart with the release name `netdata`:

```console
helm install netdata ./netdata-helmchart/charts/netdata
```

The command deploys ingress on the Kubernetes cluster in the default configuration. The [configuration](#configuration)
section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`.

Once the Netdata deployment is up and running, read our guide, [_Monitor a Kubernetes (k8s) cluster with
Netdata_](https://learn.netdata.cloud/guides/monitor/kubernetes-k8s-netdata), for a breakdown of all the collectors,
metrics, and charts available for health monitoring and performance troubleshooting.

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
 helm delete netdata
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the netdata chart and their default values.

| Parameter                                | Description                                                                                                                                            | Default                                                                                 |
|------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `kubeVersion`                            | Kubernetes version                                                                                                                                     | Autodetected                                                                            |
| `replicaCount`                           | Number of `replicas` for the parent netdata `Deployment`                                                                                               | `1`                                                                                     |
| `image.repository`                       | Container image repo                                                                                                                                   | `netdata/netdata`                                                                       |
| `image.tag`                              | Container image tag                                                                                                                                    | Latest stable netdata release                                                           |
| `image.pullPolicy`                       | Container image pull policy                                                                                                                            | `Always`                                                                                |
| `service.type`                           | Parent service type                                                                                                                                    | `ClusterIP`                                                                             |
| `service.port`                           | Parent service port                                                                                                                                    | `19999`                                                                                 |
| `service.loadBalancerIP`                 | Static LoadBalancer IP, only to be used with service type=LoadBalancer                                                                                 | `""`                                                                                    |
| `service.loadBalancerSourceRanges`       | List of allowed IPs for LoadBalancer                                                                                                                   | `[]`                                                                                    |
| `service.externalTrafficPolicy`          | Denotes if this Service desires to route external traffic to node-local or cluster-wide endpoints                                                      | `Cluster`                                                                               |
| `service.healthCheckNodePort`            | Specifies the health check node port                                                                                                                   | Allocated a port from your cluster's NodePort range                                     |
| `service.clusterIP`                      | Specific cluster IP when service type is cluster IP. Use `None` for headless service                                                                   | Allocated an IP from your cluster's service IP range                                    |
| `service.annotations`                    | Additional annotations to add to the service                                                                                                           | `{}`                                                                                    |
| `ingress.enabled`                        | Create Ingress to access the netdata web UI                                                                                                            | `true`                                                                                  |
| `ingress.apiVersion`                     | apiVersion for the Ingress                                                                                                                             | Depends on Kubernetes version                                                           |
| `ingress.annotations`                    | Associate annotations to the Ingress                                                                                                                   | `kubernetes.io/ingress.class: nginx` and `kubernetes.io/tls-acme: "true"`               |
| `ingress.path`                           | URL path for the ingress. If changed, a proxy server needs to be configured in front of netdata to translate path from a custom one to a `/`           | `/`                                                                                     |
| `ingress.pathType`                       | pathType for your ingress contrller. Default value is correct for nginx. If you use yor own ingress controller, check the correct value                | `Prefix`                                                                                |
| `ingress.hosts`                          | URL hostnames for the ingress (they need to resolve to the external IP of the ingress controller)                                                      | `netdata.k8s.local`                                                                     |
| `ingress.spec`                           | Spec section for ingress object. Everything there will be included into the object on deplyoment                                                       | `{}`                                                                                    |
| `ingress.spec.ingressClassName`          | Ingress class declaration for Kubernetes version 1.19+. Annotation ingress.class should be removed if this type of declaration is used                 | `nginx`                                                                                 |
| `rbac.create`                            | if true, create & use RBAC resources                                                                                                                   | `true`                                                                                  |
| `rbac.pspEnabled`                        | Specifies whether a PodSecurityPolicy should be created.                                                                                               | `true`                                                                                  |
| `serviceAccount.create`                  | if true, create a service account                                                                                                                      | `true`                                                                                  |
| `serviceAccount.name`                    | The name of the service account to use. If not set and create is true, a name is generated using the fullname template.                                | `netdata`                                                                               |
| `clusterrole.name`                       | Name of the cluster role linked with the service account                                                                                               | `netdata`                                                                               |
| `APIKEY`                                 | The key shared between the parent and the child netdata for streaming                                                                                  | `11111111-2222-3333-4444-555555555555`                                                  |
| `parent.port`                            | Parent's listen port                                                                                                                                   | `19999`                                                                                 |
| `parent.resources`                       | Resources for the parent deployment                                                                                                                    | `{}`                                                                                    |
| `parent.livenessProbe.failureThreshold`  | When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container  | `3`                                                                                     |
| `parent.livenessProbe.periodSeconds`     | How often (in seconds) to perform the liveness probe                                                                                                   | `30`                                                                                    |
| `parent.livenessProbe.successThreshold`  | Minimum consecutive successes for the liveness probe to be considered successful after having failed                                                   | `1`                                                                                     |
| `parent.livenessProbe.timeoutSeconds`    | Number of seconds after which the liveness probe times out                                                                                             | `1`                                                                                     |
| `parent.readinessProbe.failureThreshold` | When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready | `3`                                                                                     |
| `parent.readinessProbe.periodSeconds`    | How often (in seconds) to perform the readiness probe                                                                                                  | `30`                                                                                    |
| `parent.readinessProbe.successThreshold` | Minimum consecutive successes for the readiness probe to be considered successful after having failed                                                  | `1`                                                                                     |
| `parent.readinessProbe.timeoutSeconds`   | Number of seconds after which the readiness probe times out                                                                                            | `1`                                                                                     |
| `parent.terminationGracePeriodSeconds`   | Duration in seconds the pod needs to terminate gracefully                                                                                              | `300`                                                                                   |
| `parent.nodeSelector`                    | Node selector for the parent deployment                                                                                                                | `{}`                                                                                    |
| `parent.tolerations`                     | Tolerations settings for the parent deployment                                                                                                         | `[]`                                                                                    |
| `parent.affinity`                        | Affinity settings for the parent deployment                                                                                                            | `{}`                                                                                    |
| `parent.priorityClassName`               | Pod priority class name for the parent deployment                                                                                                      | `""`                                                                                    |
| `parent.database.persistence`            | Whether the parent should use a persistent volume for the DB                                                                                           | `true`                                                                                  |
| `parent.database.storageclass`           | The storage class for the persistent volume claim of the parent's database store, mounted to `/var/cache/netdata`                                      | the default storage class                                                               |
| `parent.database.volumesize`             | The storage space for the PVC of the parent database                                                                                                   | `2Gi`                                                                                   |
| `parent.alarms.persistence`              | Whether the parent should use a persistent volume for the alarms log                                                                                   | `true`                                                                                  |
| `parent.alarms.storageclass`             | The storage class for the persistent volume claim of the parent's alarm log, mounted to `/var/lib/netdata`                                             | the default storage class                                                               |
| `parent.alarms.volumesize`               | The storage space for the PVC of the parent alarm log                                                                                                  | `1Gi`                                                                                   |
| `parent.env`                             | Set environment parameters for the parent deployment                                                                                                   | `{}`                                                                                    |
| `parent.envFrom`                         | Set environment parameters for the parent deployment from ConfigMap and/or Secrets                                                                     | `[]`                                                                                    |
| `parent.podLabels`                       | Additional labels to add to the parent pods                                                                                                            | `{}`                                                                                    |
| `parent.podAnnotations`                  | Additional annotations to add to the parent pods                                                                                                       | `{}`                                                                                    |
| `parent.dnsPolicy`                       | DNS policy for pod                                                                                                                                     | `Default`                                                                               |
| `parent.configs`                         | Manage custom parent's configs                                                                                                                         | See [Configuration files](#configuration-files).                                        |
| `parent.claiming.enabled`                | Enable parent claiming for netdata cloud                                                                                                               | `false`                                                                                 |
| `parent.claiming.token`                  | Claim token                                                                                                                                            | `""`                                                                                    |
| `parent.claiming.room`                   | Comma separated list of claim rooms IDs                                                                                                                | `""`                                                                                    |
| `child.enabled`                          | Install child daemonset to gather data from nodes                                                                                                      | `true`                                                                                  |
| `child.port`                             | Children's listen port                                                                                                                                 | `service.port` (Same as parent's listen port)                                           |
| `child.updateStrategy`                   | An update strategy to replace existing DaemonSet pods with new pods                                                                                    | `{}`                                                                                    |
| `child.resources`                        | Resources for the child daemonsets                                                                                                                     | `{}`                                                                                    |
| `child.livenessProbe.failureThreshold`   | When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container  | `3`                                                                                     |
| `child.livenessProbe.periodSeconds`      | How often (in seconds) to perform the liveness probe                                                                                                   | `30`                                                                                    |
| `child.livenessProbe.successThreshold`   | Minimum consecutive successes for the liveness probe to be considered successful after having failed                                                   | `1`                                                                                     |
| `child.livenessProbe.timeoutSeconds`     | Number of seconds after which the liveness probe times out                                                                                             | `1`                                                                                     |
| `child.readinessProbe.failureThreshold`  | When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready | `3`                                                                                     |
| `child.readinessProbe.periodSeconds`     | How often (in seconds) to perform the readiness probe                                                                                                  | `30`                                                                                    |
| `child.readinessProbe.successThreshold`  | Minimum consecutive successes for the readiness probe to be considered successful after having failed                                                  | `1`                                                                                     |
| `child.readinessProbe.timeoutSeconds`    | Number of seconds after which the readiness probe times out                                                                                            | `1`                                                                                     |
| `child.terminationGracePeriodSeconds`    | Duration in seconds the pod needs to terminate gracefully                                                                                              | `30`                                                                                    |
| `child.nodeSelector`                     | Node selector for the child daemonsets                                                                                                                 | `{}`                                                                                    |
| `child.tolerations`                      | Tolerations settings for the child daemonsets                                                                                                          | `- operator: Exists` with `effect: NoSchedule`                                          |
| `child.affinity`                         | Affinity settings for the child daemonsets                                                                                                             | `{}`                                                                                    |
| `child.priorityClassName`                | Pod priority class name for the child daemonsets                                                                                                       | `""`                                                                                    |
| `child.env`                              | Set environment parameters for the child daemonset                                                                                                     | `{}`                                                                                    |
| `child.envFrom`                          | Set environment parameters for the child daemonset from ConfigMap and/or Secrets                                                                       | `[]`                                                                                    |
| `child.podLabels`                        | Additional labels to add to the child pods                                                                                                             | `{}`                                                                                    |
| `child.podAnnotations`                   | Additional annotations to add to the child pods                                                                                                        | `{}`                                                                                    |
| `child.hostNetwork`                      | Usage of host networking and ports                                                                                                                     | `true`                                                                                  |
| `child.dnsPolicy`                        | DNS policy for pod. Should be `ClusterFirstWithHostNet` if `child.hostNetwork = true`                                                                  | `ClusterFirstWithHostNet`                                                               |
| `child.podAnnotationAppArmor.enabled`    | Whether or not to include the AppArmor security annotation                                                                                             | `true`                                                                                  |
| `child.persistence.hostPath`             | Host node directory for storing child instance data                                                                                                    | `/var/lib/netdata-k8s-child`                                                            |
| `child.persistence.enabled`              | Whether or not to persist `/var/lib/netdata` in the `child.persistence.hostPath`.                                                                      | `true`                                                                                  |
| `child.configs`                          | Manage custom child's configs                                                                                                                          | See [Configuration files](#configuration-files).                                        |
| `child.claiming.enabled`                 | Enable child claiming for netdata cloud                                                                                                                | `false`                                                                                 |
| `child.claiming.token`                   | Claim token                                                                                                                                            | `""`                                                                                    |
| `child.claiming.room`                    | Comma separated list of claim rooms IDs                                                                                                                | `""`                                                                                    |
| `notifications.slackurl`                 | URL for slack notifications                                                                                                                            | `""`                                                                                    |
| `notifications.slackrecipient`           | Slack recipient list                                                                                                                                   | `""`                                                                                    |
| `initContainersImage.repository`         | Init containers' image repository                                                                                                                      | `alpine`                                                                                |
| `initContainersImage.tag`                | Init containers' image tag                                                                                                                             | `latest`                                                                                |
| `initContainersImage.pullPolicy`         | Init containers' image pull policy                                                                                                                     | `Always`                                                                                |
| `sysctlInitContainer.enabled`            | Enable an init container to modify Kernel settings                                                                                                     | `false`                                                                                 |
| `sysctlInitContainer.command`            | sysctl init container command to execute                                                                                                               | []                                                                                      |
| `sysctlInitContainer.resources`          | sysctl Init container CPU/Memory resource requests/limits                                                                                              | {}                                                                                      |
| `sd.image.repository`                    | Service-discovery image repo                                                                                                                           | `netdata/agent-sd`                                                                      |
| `sd.image.tag`                           | Service-discovery image tag                                                                                                                            | Latest stable release (e.g. `v0.2.2`)                                                   |
| `sd.image.pullPolicy`                    | Service-discovery image pull policy                                                                                                                    | `Always`                                                                                |
| `sd.child.enabled`                       | Add service-discovery sidecar container to the netdata child pod definition                                                                            | `true`                                                                                  |
| `sd.child.resources`                     | Child service-discovery container CPU/Memory resource requests/limits                                                                                  | `{resources: {limits: {cpu: 50m, memory: 150Mi}, requests: {cpu: 50m, memory: 100Mi}}}` |
| `sd.child.configmap.name`                | Child service-discovery ConfigMap name                                                                                                                 | `netdata-child-sd-config-map`                                                           |
| `sd.child.configmap.key`                 | Child service-discovery ConfigMap key                                                                                                                  | `config.yml`                                                                            |
| `sd.child.configmap.from.file`           | File to use for child service-discovery configuration generation                                                                                       | `sdconfig/sd-child.yml`                                                                 |
| `sd.child.configmap.from.value`          | Value to use for child service-discovery configuration generation                                                                                      | `{}`                                                                                    |

Example to set the parameters from the command line:

```console
$ helm install ./netdata --name my-release \
    --set notifications.slackurl=MySlackAPIURL \
    --set notifications.slackrecipiet="@MyUser MyChannel"
```

Another example, to set a different ingress controller.

By default `kubernetes.io/ingress.class` set to use `nginx` as an ingress controller, but you can set `Traefik` as your
ingress controller by setting `ingress.annotations`.

```
$ helm install ./netdata --name my-release \
    --set ingress.annotations=kubernetes.io/ingress.class: traefik
```

Alternatively to passing each variable in the command line, a YAML file that specifies the values for the parameters can
be provided while installing the chart. For example,

```console
$ helm install ./netdata --name my-release -f values.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)

> **Note:**: To opt out of anonymous statistics, set the `DO_NOT_TRACK`
environment variable to non-zero or non-empty value in
`parent.env` / `child.env` configuration (e.g: `DO_NOT_TRACK: 1`)
or uncomment the line in `values.yml`.

### Configuration files

| Parameter                  | Description                                                                           | Default                                                                                                                       |
|----------------------------|---------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| `parent.configs.netdata`   | Contents of the parent's `netdata.conf`                                               | `memory mode = dbengine`                                                                                                          |
| `parent.configs.stream`    | Contents of the parent's `stream.conf`                                                | Store child data, accept all connections, and issue alarms for child data.                                                    |
| `parent.configs.health`    | Contents of `health_alarm_notify.conf`                                                | Email disabled, a sample of the required settings for Slack notifications                                                     |
| `parent.configs.exporting` | Contents of `exporting.conf`                                                          | Disabled                                                                                                                      |
| `child.configs.netdata`    | Contents of the child's `netdata.conf`                                                | No persistent storage, no alarms, no UI                                                                                       |
| `child.configs.stream`     | Contents of the child's `stream.conf`                                                 | Send metrics to the parent at netdata:{{ service.port }}                                                                      |
| `child.configs.exporting`  | Contents of the child's `exporting.conf`                                              | Disabled                                                                                                                      |
| `child.configs.kubelet`    | Contents of the child's `go.d/k8s_kubelet.conf` that drives the kubelet collector     | Update metrics every sec, do not retry to detect the endpoint, look for the kubelet metrics at http://127.0.0.1:10255/metrics |
| `child.configs.kubeproxy`  | Contents of the child's `go.d/k8s_kubeproxy.conf` that drives the kubeproxy collector | Update metrics every sec, do not retry to detect the endpoint, look for the coredns metrics at http://127.0.0.1:10249/metrics |

To deploy additional netdata user configuration files, you will need to add similar entries to either
the `parent.configs` or the `child.configs` arrays. Regardless of whether you add config files that reside directly
under `/etc/netdata` or in a subdirectory such as `/etc/netdata/go.d`, you can use the already provided configurations
as reference. For reference, the `parent.configs` the array includes an `example` alarm that would get triggered if the
python.d `example` module was enabled.

Note that with the default configuration of this chart, the parent does the health checks and triggers alarms, but does
not collect much data. As a result, the only other configuration files that might make sense to add to the parent are
the alarm and alarm template definitions, under `/etc/netdata/health.d`.

> **Tip**: Do pay attention to the indentation of the config file contents, as it matters for the parsing of the `yaml` file. Note that the first line under `var: |`
must be indented with two more spaces relative to the preceding line:

```
  data: |-
    config line 1 #Need those two spaces
        config line 2 #No problem indenting more here
```

### Persistent volumes

There are two different persistent volumes on `parent` node by design (not counting any Configmap/Secret mounts). Both
can be used, but they don't have to be. Keep in mind that whenever persistent volumes for `parent` are not used, all the
data for specific PV is lost in case of pod removal.

1. database (`/var/cache/netdata`) - all metrics data is stored here. Performance of this volume affects query timings.
2. alarms (`/var/lib/netdata`) - alarm log, if not persistent pod recreation will result in parent appearing as a new
   node in `netdata.cloud` (due to `./registry/` and `./cloud.d/` being removed).

In case of `child` instance it is a bit simpler. By default, hostPath: `/var/lib/netdata-k8s-child` is mounted on child
in: `/var/lib/netdata`. You can disable it but this option is pretty much required in a real life scenario, as without
it each pod deletion will result in new replication node for a parent.

### Service discovery and supported services

Netdata's [service discovery](https://github.com/netdata/agent-service-discovery/), which is installed as part of the
Helm chart installation, finds what services are running on a cluster's pods, converts that into configuration files,
and exports them, so they can be monitored.

#### Applications

Service discovery currently supports the following applications via their associated collector:

- [ActiveMQ](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/activemq)
- [Apache](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/apache)
- [Bind](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/bind)
- [CockroachDB](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/cockroachdb)
- [Consul](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/consul)
- [CoreDNS](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/coredns)
- [Elasticsearch](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/elasticsearch)
- [Fluentd](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/fluentd)
- [FreeRADIUS](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/freeradius)
- [HDFS](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/hdfs)
- [Lighttpd](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/lighttpd)
- [Lighttpd2](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/lighttpd2)
- [Logstash](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/logstash)
- [MySQL](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/mysql)
- [NGINX](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/nginx)
- [OpenVPN](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/openvpn)
- [PHP-FPM](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/phpfpm)
- [RabbitMQ](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/rabbitmq)
- [Solr](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/solr)
- [Tengine](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/tengine)
- [Unbound](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/unbound)
- [VerneMQ](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/vernemq)
- [ZooKeeper](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/zookeeper)

#### Prometheus endpoints

Service discovery supports Prometheus endpoints via
the [Prometheus](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/prometheus) collector.

Annotations on pods allow a fine control of the scraping process:

- `prometheus.io/scrape`: The default configuration will scrape all pods and, if set to false, this annotation excludes
  the pod from the scraping process.
- `prometheus.io/path`: If the metrics path is not _/metrics_, define it with this annotation.
- `prometheus.io/port`: Scrape the pod on the indicated port instead of the pod’s declared ports.

#### Configure service discovery

If your cluster runs services on non-default ports or uses non-default names, you may need to configure service
discovery to start collecting metrics from your services. You have to edit
the [default ConfigMap](https://github.com/netdata/helmchart/blob/master/sdconfig/child.yml) that is shipped with the
Helmchart and deploy that to your cluster.

First, copy `netdata-helmchart/sdconfig/child.yml` to a new location outside the `netdata-helmchart` directory. The
destination can be anywhere you like, but the following examples assume it resides next to the `netdata-helmchart`
directory.

```bash
cp netdata-helmchart/sdconfig/child.yml .
```

Edit the new `child.yml` file according to your needs. See
the [Helm chart configuration](https://github.com/netdata/helmchart#configuration) and the file itself for details. You
can then run
`helm install`/`helm upgrade` with the `--set-file` argument to use your configured `child.yml` file instead of the
default, changing the path if you copied it elsewhere.

```bash
helm install --set-file sd.child.configmap.from.value=./child.yml netdata ./netdata-helmchart/charts/netdata
helm upgrade --set-file sd.child.configmap.from.value=./child.yml netdata ./netdata-helmchart/charts/netdata
```

Now that you pushed an edited ConfigMap to your cluster, service discovery should find and set up metrics collection
from your non-default service.

### Custom pod labels and annotations

Occasionally, you will want to add
specific [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
and [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) to the parent and/or
child pods. You might want to do this to tell other applications on the cluster how to treat your pods, or simply to
categorize applications on your cluster. You can label and annotate the parent and child pods by using the `podLabels`
and `podAnnotations` dictionaries under the `parent` and `child` objects, respectively.

For example, suppose you're installing Netdata on all your database nodes, and you'd like the child pods to be labeled
with `workload: database` so that you're able to recognize this.

At the same time, say you've configured [chaoskube](https://github.com/helm/charts/tree/master/stable/chaoskube) to kill
all pods annotated with `chaoskube.io/enabled: true`, and you'd like chaoskube to be enabled for the parent pod but not
the childs.

You would do this by installing as:

```console
$ helm install \
  --set child.podLabels.workload=database \
  --set 'child.podAnnotations.chaoskube\.io/enabled=false' \
  --set 'parent.podAnnotations.chaoskube\.io/enabled=true' \
  netdata ./netdata-helmchart/charts/netdata
```

## Contributing

If you want to contribute, we are humbled!

- Take a look at our [Contributing Guidelines](https://learn.netdata.cloud/contribute/handbook).
- This repository is under the [Netdata Code Of Conduct](https://learn.netdata.cloud/contribute/code-of-conduct).
- Chat about your contribution and let us help you in
  our [forum](https://community.netdata.cloud/c/agent-development/9)!
