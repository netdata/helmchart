# Netdata Helm chart for Kubernetes deployments

[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/netdata)](https://artifacthub.io/packages/search?repo=netdata)

_Based on the work of varyumin (https://github.com/varyumin/netdata)_.

**This Helm chart is in beta**.

## Introduction

This chart bootstraps a [Netdata](https://github.com/netdata/netdata) deployment on a [Kubernetes](http://kubernetes.io)
cluster using the [Helm](https://helm.sh) package manager.

The chart installs a Netdata child pod on each node of a cluster, using a `Daemonset` if not disabled, and a Netdata
parent pod on one node, using a `Deployment`. The child pods function as headless collectors that collect and forward
all the metrics to the parent pod. The parent pod uses persistent volumes to store metrics and alarms, handle alarm
notifications, and provide the Netdata UI to view metrics using an ingress controller.

Please validate that the settings are suitable for your cluster before using them in production.

## Prerequisites

-   A working cluster running Kubernetes v1.9 or newer.
-   The [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) command line tool, within [one minor version
    difference](https://kubernetes.io/docs/tasks/tools/install-kubectl/#before-you-begin) of your cluster, on an
    administrative system.
-   The [Helm package manager](https://helm.sh/) v3.0.0 or newer on the same administrative system.

## Installing the Chart

**See our [install Netdata on Kubernetes](https://learn.netdata.cloud/docs/agent/packaging/installer/methods/kubernetes)
documentation for detailed installation and configuration instructions.**

### Installing via our Helm repository

To use Netdata's Helm repository, please follow the instructions [here](https://netdata.github.io/helmchart/)

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

The command removes all the Kubernetes components associated with the chart and
deletes the release.

## Configuration

The following table lists the configurable parameters of the netdata chart and their default values.

| Parameter                                | Description                                                                                                                                            | Default                                                                   |
|------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| `replicaCount`                           | Number of `replicas` for the parent netdata `Deployment`                                                                                               | `1`                                                                       |
| `image.repository`                       | Container image repo                                                                                                                                   | `netdata/netdata`                                                         |
| `image.tag`                              | Container image tag                                                                                                                                    | Latest stable netdata release (e.g. `v1.26.0`)                            |
| `image.pullPolicy`                       | Container image pull policy                                                                                                                            | `Always`                                                                  |
| `service.type`                           | Parent service type                                                                                                                                    | `ClusterIP`                                                               |
| `service.port`                           | Parent service port                                                                                                                                    | `19999`                                                                   |
| `service.loadBalancerIP`                 | Static LoadBalancer IP, only to be used with service type=LoadBalancer                                                                                 | `""`                                                                      |
| `ingress.enabled`                        | Create Ingress to access the netdata web UI                                                                                                            | `true`                                                                    |
| `ingress.annotations`                    | Associate annotations to the Ingress                                                                                                                   | `kubernetes.io/ingress.class: nginx` and `kubernetes.io/tls-acme: "true"` |
| `ingress.path`                           | URL path for the ingress                                                                                                                               | `/`                                                                       |
| `ingress.hosts`                          | URL hostnames for the ingress (they need to resolve to the external IP of the ingress controller)                                                      | `netdata.k8s.local`                                                       |
| `rbac.create`                            | if true, create & use RBAC resources                                                                                                                   | `true`                                                                    |
| `rbac.pspEnabled`                        | Specifies whether a PodSecurityPolicy should be created.                                                                                               | `true`                                                                    |
| `serviceAccount.create`                  | if true, create a service account                                                                                                                      | `true`                                                                    |
| `serviceAccount.name`                    | The name of the service account to use. If not set and create is true, a name is generated using the fullname template.                                | `netdata`                                                                 |
| `clusterrole.name`                       | Name of the cluster role linked with the service account                                                                                               | `netdata`                                                                 |
| `APIKEY`                                 | The key shared between the parent and the child netdata for streaming                                                                                  | `11111111-2222-3333-4444-555555555555`                                    |
| `parent.resources`                       | Resources for the parent deployment                                                                                                                    | `{}`                                                                      |
| `parent.livenessProbe.failureThreshold`  | When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container  | `3`                                                                       |
| `parent.livenessProbe.periodSeconds`     | How often (in seconds) to perform the liveness probe                                                                                                   | `30`                                                                      |
| `parent.livenessProbe.successThreshold`  | Minimum consecutive successes for the liveness probe to be considered successful after having failed                                                   | `1`                                                                       |
| `parent.livenessProbe.timeoutSeconds`    | Number of seconds after which the liveness probe times out                                                                                             | `1`                                                                       |
| `parent.readinessProbe.failureThreshold` | When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready | `3`                                                                       |
| `parent.readinessProbe.periodSeconds`    | How often (in seconds) to perform the readiness probe                                                                                                  | `30`                                                                      |
| `parent.readinessProbe.successThreshold` | Minimum consecutive successes for the readiness probe to be considered successful after having failed                                                  | `1`                                                                       |
| `parent.readinessProbe.timeoutSeconds`   | Number of seconds after which the readiness probe times out                                                                                            | `1`                                                                       |
| `parent.terminationGracePeriodSeconds`   | Duration in seconds the pod needs to terminate gracefully                                                                                              | `300`                                                                     |
| `parent.nodeSelector`                    | Node selector for the parent deployment                                                                                                                | `{}`                                                                      |
| `parent.tolerations`                     | Tolerations settings for the parent deployment                                                                                                         | `[]`                                                                      |
| `parent.affinity`                        | Affinity settings for the parent deployment                                                                                                            | `{}`                                                                      |
| `parent.priorityClassName`               | Pod priority class name for the parent deployment                                                                                                      | `""`                                                                      |
| `parent.database.persistence`            | Whether the parent should use a persistent volume for the DB                                                                                           | `true`                                                                    |
| `parent.database.storageclass`           | The storage class for the persistent volume claim of the parent's database store, mounted to `/var/cache/netdata`                                      | the default storage class                                                 |
| `parent.database.volumesize`             | The storage space for the PVC of the parent database                                                                                                   | `2Gi`                                                                     |
| `parent.alarms.persistence`              | Whether the parent should use a persistent volume for the alarms log                                                                                   | `true`                                                                    |
| `parent.alarms.storageclass`             | The storage class for the persistent volume claim of the parent's alarm log, mounted to `/var/lib/netdata`                                             | the default storage class                                                 |
| `parent.alarms.volumesize`               | The storage space for the PVC of the parent alarm log                                                                                                  | `100Mi`                                                                   |
| `parent.env`                             | Set environment parameters for the parent deployment                                                                                                   | `{}`                                                                      |
| `parent.podLabels`                       | Additional labels to add to the parent pods                                                                                                            | `{}`                                                                      |
| `parent.podAnnotations`                  | Additional annotations to add to the parent pods                                                                                                       | `{}`                                                                      |
| `parent.configs`                         | Manage custom parent's configs                                                                                                                         | See [Configuration files](#configuration-files).                          |
| `parent.claiming.enabled`                | Enable parent claiming for netdata cloud                                                                                                               | `false`                                                                   |
| `parent.claiming.token`                  | Claim token                                                                                                                                            | `""`                                                                      |
| `parent.claiming.room`                   | Comma separated list of claim rooms IDs                                                                                                                | `""`                                                                      |
| `child.enabled`                          | Install child daemonset to gather data from nodes                                                                                                      | `true`                                                                    |
| `child.port`                             | Children's listen port                                                                                                                                 | `service.port` (Same as parent's listen port)                             |
| `child.updateStrategy`                   | An update strategy to replace existing DaemonSet pods with new pods                                                                                    | `{}`                                                                      |
| `child.resources`                        | Resources for the child daemonsets                                                                                                                     | `{}`                                                                      |
| `child.livenessProbe.failureThreshold`   | When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container  | `3`                                                                       |
| `child.livenessProbe.periodSeconds`      | How often (in seconds) to perform the liveness probe                                                                                                   | `30`                                                                      |
| `child.livenessProbe.successThreshold`   | Minimum consecutive successes for the liveness probe to be considered successful after having failed                                                   | `1`                                                                       |
| `child.livenessProbe.timeoutSeconds`     | Number of seconds after which the liveness probe times out                                                                                             | `1`                                                                       |
| `child.readinessProbe.failureThreshold`  | When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready | `3`                                                                       |
| `child.readinessProbe.periodSeconds`     | How often (in seconds) to perform the readiness probe                                                                                                  | `30`                                                                      |
| `child.readinessProbe.successThreshold`  | Minimum consecutive successes for the readiness probe to be considered successful after having failed                                                  | `1`                                                                       |
| `child.readinessProbe.timeoutSeconds`    | Number of seconds after which the readiness probe times out                                                                                            | `1`                                                                       |
| `child.terminationGracePeriodSeconds`    | Duration in seconds the pod needs to terminate gracefully                                                                                              | `30`                                                                      |
| `child.nodeSelector`                     | Node selector for the child daemonsets                                                                                                                 | `{}`                                                                      |
| `child.tolerations`                      | Tolerations settings for the child daemonsets                                                                                                          | `- operator: Exists` with `effect: NoSchedule`                            |
| `child.affinity`                         | Affinity settings for the child daemonsets                                                                                                             | `{}`                                                                      |
| `child.priorityClassName`                | Pod priority class name for the child daemonsets                                                                                                       | `""`                                                                      |
| `child.env`                              | Set environment parameters for the child daemonset                                                                                                     | `{}`                                                                      |
| `child.podLabels`                        | Additional labels to add to the child pods                                                                                                             | `{}`                                                                      |
| `child.podAnnotations`                   | Additional annotations to add to the child pods                                                                                                        | `{}`                                                                      |
| `child.podAnnotationAppArmor.enabled`    | Whether or not to include the AppArmor security annotation                                                                                             | `true`                                                                    |
| `child.persistUniqueID`                  | Whether or not to persist `netdata.public.unique.id` across restarts                                                                                   | `true`                                                                    |
| `child.configs`                          | Manage custom child's configs                                                                                                                          | See [Configuration files](#configuration-files).                          |
| `notifications.slackurl`                 | URL for slack notifications                                                                                                                            | `""`                                                                      |
| `notifications.slackrecipient`           | Slack recipient list                                                                                                                                   | `""`                                                                      |
| `sysctlImage.enabled`                    | Enable an init container to modify Kernel settings                                                                                                     | `false`                                                                   |
| `sysctlImage.command`                    | sysctlImage command to execute                                                                                                                         | []                                                                        |
| `sysctlImage.repository`                 | sysctlImage Init container name                                                                                                                        | `alpine`                                                                  |
| `sysctlImage.tag`                        | sysctlImage Init container tag                                                                                                                         | `latest`                                                                  |
| `sysctlImage.pullPolicy`                 | sysctlImage Init container pull policy                                                                                                                 | `Always`                                                                  |
| `sysctlImage.resources`                  | sysctlImage Init container CPU/Memory resource requests/limits                                                                                         | {}                                                                        |
| `sd.image.repository`                    | Service-discovery image repo                                                                                                                           | `netdata/agent-sd`                                                        |
| `sd.image.tag`                           | Service-discovery image tag                                                                                                                            | Latest stable release (e.g. `v0.1.0`)                                     |
| `sd.image.pullPolicy`                    | Service-discovery image pull policy                                                                                                                    | `Always`                                                                  |
| `sd.child.enabled`                       | Add service-discovery sidecar container to the netdata child pod definition                                                                            | `true`                                                                    |
| `sd.child.resources`                     | Child service-discovery container CPU/Memory resource requests/limits                                                                                  | `{}`                                                                      |
| `sd.child.configmap.name`                | Child service-discovery ConfigMap name                                                                                                                 | `netdata-child-sd-config-map`                                             |
| `sd.child.configmap.key`                 | Child service-discovery ConfigMap key                                                                                                                  | `config.yml`                                                              |
| `sd.child.configmap.from.file`           | File to use for child service-discovery configuration generation                                                                                       | `sdconfig/sd-child.yml`                                                   |
| `sd.child.configmap.from.value`          | Value to use for child service-discovery configuration generation                                                                                      | `{}`                                                                      |

Example to set the parameters from the command line:
```console
$ helm install ./netdata --name my-release \
    --set notifications.slackurl=MySlackAPIURL \
    --set notifications.slackrecipiet="@MyUser MyChannel"
```

Another example, to set a different ingress controller.

By default `kubernetes.io/ingress.class` set to use `nginx` as an ingress controller but you can set `Traefik` as your ingress controller by setting `ingress.annotations`.
```
$ helm install ./netdata --name my-release \
    --set ingress.annotations=kubernetes.io/ingress.class: traefik
```

Alternatively to passing each variable in the command line, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

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
| `parent.configs.netdata`   | Contents of the parent's `netdata.conf`                                               | `memory mode = save`                                                                                                          |
| `parent.configs.stream`    | Contents of the parent's `stream.conf`                                                | Store child data, accept all connections, and issue alarms for child data.                                                    |
| `parent.configs.health`    | Contents of `health_alarm_notify.conf`                                                | Email disabled, a sample of the required settings for Slack notifications                                                     |
| `parent.configs.exporting` | Contents of `exporting.conf`                                                          | Disabled                                                                                                                      |
| `child.configs.netdata`    | Contents of the child's `netdata.conf`                                                | No persistent storage, no alarms, no UI                                                                                       |
| `child.configs.stream`     | Contents of the child's `stream.conf`                                                 | Send metrics to the parent at netdata:{{ service.port }}                                                                      |
| `child.configs.exporting`  | Contents of the child's `exporting.conf`                                              | Disabled                                                                                                                      |
| `child.configs.kubelet`    | Contents of the child's `go.d/k8s_kubelet.conf` that drives the kubelet collector     | Update metrics every sec, do not retry to detect the endpoint, look for the kubelet metrics at http://127.0.0.1:10255/metrics |
| `child.configs.kubeproxy`  | Contents of the child's `go.d/k8s_kubeproxy.conf` that drives the kubeproxy collector | Update metrics every sec, do not retry to detect the endpoint, look for the coredns metrics at http://127.0.0.1:10249/metrics |

To deploy additional netdata user configuration files, you will need to add similar entries to either the parent.configs or the child. configs arrays. Regardless of whether you add config files that reside directly under `/etc/netdata` or in a subdirectory such as `/etc/netdata/go.d`, you can use the already provided configurations as reference. For reference, the `parent.configs` the array includes an `example` alarm that would get triggered if the python.d `example` module was enabled.

Note that with the default configuration of this chart, the parent does the health checks and triggers alarms, but does not collect much data. As a result, the only other configuration files that might make sense to add to the parent are the alarm and alarm template definitions, under `/etc/netdata/health.d`.

> **Tip**: Do pay attention to the indentation of the config file contents, as it matters for the parsing of the `yaml` file. Note that the first line under `var: |`
must be indented with two more spaces relative to the preceding line:

```
  data: |-
    config line 1 #Need those two spaces
        config line 2 #No problem indenting more here
```

### Service discovery and supported services

Netdata's [service discovery](https://github.com/netdata/agent-service-discovery/), which is installed as part of the
Helm chart installation, finds what services are running on a cluster's pods, converts that into configuration files,
and exports them so they can be monitored.

#### Applications

Service discovery currently supports the following applications via their associated collector:

-   [ActiveMQ](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/activemq)
-   [Apache](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/apache)
-   [Bind](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/bind)
-   [CockroachDB](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/cockroachdb)
-   [Consul](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/consul)
-   [CoreDNS](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/coredns)
-   [Elasticsearch](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/elasticsearch)
-   [Fluentd](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/fluentd)
-   [FreeRADIUS](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/freeradius)
-   [HDFS](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/hdfs)
-   [Lighttpd](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/lighttpd)
-   [Lighttpd2](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/lighttpd2)
-   [Logstash](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/logstash)
-   [MySQL](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/mysql)
-   [NGINX](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/nginx)
-   [OpenVPN](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/openvpn)
-   [PHP-FPM](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/phpfpm)
-   [RabbitMQ](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/rabbitmq)
-   [Solr](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/solr)
-   [Tengine](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/tengine)
-   [Unbound](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/unbound)
-   [VerneMQ](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/vernemq)
-   [ZooKeeper](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/zookeeper)

#### Prometheus endpoints

Service discovery supports Prometheus endpoints via the [Prometheus](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/prometheus) collector.

Annotations on pods allow a fine control of the scraping process:

-   `prometheus.io/scrape`: The default configuration will scrape all pods and, if set to false, this annotation excludes the pod from the scraping process.
-   `prometheus.io/path`: If the metrics path is not _/metrics_, define it with this annotation.
-   `prometheus.io/port`: Scrape the pod on the indicated port instead of the pod’s declared ports.

#### Configure service discovery

If your cluster runs services on non-default ports or uses non-default names, you may need to configure service
discovery to start collecting metrics from your services. You have to edit the [default
ConfigMap](https://github.com/netdata/helmchart/blob/master/sdconfig/child.yml) that is shipped with the Helmchart and
deploy that to your cluster.

First, copy `netdata-helmchart/sdconfig/child.yml` to a new location outside the `netdata-helmchart` directory. The
destination can be anywhere you like, but the following examples assume it resides next to the `netdata-helmchart`
directory.

```bash
cp netdata-helmchart/sdconfig/child.yml .
```

Edit the new `child.yml` file according to your needs. See the [Helm chart
configuration](https://github.com/netdata/helmchart#configuration) and the file itself for details. You can then run
`helm install`/`helm upgrade` with the `--set-file` argument to use your configured `child.yml` file instead of the
default, changing the path if you copied it elsewhere.

```bash
helm install --set-file sd.child.configmap.from.value=./child.yml netdata ./netdata-helmchart
helm upgrade --set-file sd.child.configmap.from.value=./child.yml netdata ./netdata-helmchart
```

Now that you pushed an edited ConfigMap to your cluster, service discovery should find and set up metrics collection
from your non-default service.

### Custom pod labels and annotations

Occasionally, you will want to add specific [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) and [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) to the parent and/or child pods.
You might want to do this to tell other applications on the cluster how to treat your pods, or simply to categorize applications on your cluster.
You can label and annotate the parent and child pods by using the `podLabels` and `podAnnotations` dictionaries under the `parent` and `child` objects, respectively.

For example, suppose you're installing netdata on all your database nodes, and you'd like the child pods to be labeled with `workload: database` so that you're able to recognize this.
At the same time, say you've configured [chaoskube](https://github.com/helm/charts/tree/master/stable/chaoskube) to kill all pods annotated with `chaoskube.io/enabled: true`, and you'd like chaoskube to be enabled for the parent pod but not the childs.
You would do this by installing as:

```console
$ helm install ./netdata --name my-release \
    --set child.podLabels.workload=database \
    --set 'child.podAnnotations.chaoskube\.io/enabled=false' \
    --set 'parent.podAnnotations.chaoskube\.io/enabled=true'
```
