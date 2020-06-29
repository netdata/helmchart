# Netdata Helm chart for kubernetes deployments

_Based on the work of varyumin (https://github.com/varyumin/netdata)_

**This Helm chart is in Beta**. 
Please validate that the settings are suitable for your cluster, before using 
them in production 

## Introduction

This chart bootstraps a [netdata](https://github.com/netdata/netdata) deployment 
on a  [Kubernetes](http://kubernetes.io) cluster using the 
[Helm](https://helm.sh) package manager.

The chart installs a netdata child pod on each node of a cluster, using a 
`Daemonset` if not disabled, and a netdata parent pod on one node, using a `Statefulset`.
The child function as headless collectors that simply collect and forward all the metrics to the parent netdata.
The parent uses persistent volumes to store metrics and alarms, handles alarm notifications and provides the netdata UI to view the metrics, using an ingress controller.

## Prerequisites
  - Kubernetes 1.9+

## Installing the Chart

Clone the repository locally

```console
$ git clone https://github.com/netdata/helmchart.git netdata
```

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release ./netdata
```

The command deploys nginx-ingress on the Kubernetes cluster in the default configuration.
The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release --purge
```

The command removes all the Kubernetes components associated with the chart and 
deletes the release.

## Configuration

The following table lists the configurable parameters of the netdata chart and their default values.

Parameter | Description | Default
--- | --- | ---
`replicaCount` | Number of `replicas` for the parent netdata `Statefulset` | `1`
`image.repository` | Container image repo | `netdata/netdata`
`image.tag` | Container image tag | Latest stable netdata release (e.g. `v1.23.0`)
`image.pullPolicy` | Container image pull policy | `Always`
`service.type` | netdata parent service type | `ClusterIP`
`service.port` | netdata parent service port | `19999`
`service.loadBalancerIP`| Static LoadBalancer IP, only to be used with service type=LoadBalancer|`""`
`ingress.enabled` | Create Ingress to access the netdata web UI | `true`
`ingress.annotations` | Associate annotations to the Ingress | `kubernetes.io/ingress.class: nginx` and `kubernetes.io/tls-acme: "true"`
`ingress.path` | URL path for the ingress | `/`
`ingress.hosts` | URL hostnames for the ingress (they need to resolve to the external IP of the ingress controller) | `netdata.k8s.local`
`rbac.create` | if true, create & use RBAC resources | `true`
`rbac.pspEnabled` | Specifies whether a PodSecurityPolicy should be created. | `true`
`serviceAccount.create` |if true, create a service account | `true`
`serviceAccount.name` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. | `netdata`
`clusterrole.name` | Name of the cluster role linked with the service account | `netdata`
`APIKEY` | The key shared between the parent and the child netdata for streaming | `11111111-2222-3333-4444-555555555555`
`parent.resources` | Resources for the parent statefulset | `{}`
`parent.nodeSelector` | Node selector for the parent statefulset | `{}`
`parent.tolerations` | Tolerations settings for the parent statefulset | `[]`
`parent.affinity` | Affinity settings for the parent statefulset | `{}`
`parent.priorityClassName` | Pod priority class name for the parent statefulset | `""`
`parent.database.persistence` | Whether the parent should use a persistent volume for the DB | `true`
`parent.database.storageclass` | The storage class for the persistent volume claim of the parent's database store, mounted to `/var/cache/netdata` | the default storage class
`parent.database.volumesize` | The storage space for the PVC of the parent database | `2Gi`
`parent.alarms.persistence` | Whether the parent should use a persistent volume for the alarms log | `true`
`parent.alarms.storageclass` | The storage class for the persistent volume claim of the parent's alarm log, mounted to `/var/lib/netdata` | the default storage class
`parent.alarms.volumesize` | The storage space for the PVC of the parent alarm log | `100Mi`
`parent.env` | Set environment parameters for the parent statefulset | `{}`
`parent.podLabels` | Additional labels to add to the parent pods | `{}`
`parent.podAnnotations` | Additional annotations to add to the parent pods | `{}`
`parent.configs` | Manage custom parent's configs | See [Configuration files](#configuration-files).
`child.enabled` | Install child daemonset to gather data from nodes | `true`
`child.resources` | Resources for the child daemonsets | `{}`
`child.nodeSelector` | Node selector for the child daemonsets | `{}`
`child.tolerations` | Tolerations settings for the child daemonsets | `- operator: Exists` with `effect: NoSchedule`
`child.affinity` | Affinity settings for the child daemonsets | `{}`
`child.priorityClassName` | Pod priority class name for the child daemonsets | `""`
`child.env` | Set environment parameters for the child daemonset | `{}`
`child.podLabels` | Additional labels to add to the child pods | `{}`
`child.podAnnotations` | Additional annotations to add to the child pods | `{}`
`child.podAnnotationAppArmor.enabled` | Whether or not to include the AppArmor security annotation | `true`
`child.persistUniqueID` | Whether or not to persist `netdata.public.unique.id` across restarts | `true`
`child.configs` | Manage custom child's configs | See [Configuration files](#configuration-files).
`notifications.slackurl` | URL for slack notifications | `""`
`notifications.slackrecipient` | Slack recipient list | `""`
`sysctlImage.enabled` | Enable an init container to modify Kernel settings | `false` |
`sysctlImage.command` | sysctlImage command to execute | [] |
`sysctlImage.repository`| sysctlImage Init container name | `alpine` |
`sysctlImage.tag` | sysctlImage Init container tag | `latest` |
`sysctlImage.pullPolicy` | sysctlImage Init container pull policy | `Always` |
`sysctlImage.resources` | sysctlImage Init container CPU/Memory resource requests/limits | {} |
`sd.image.repository` | Service-discovery image repo | `netdata/agent-sd`
`sd.image.tag` | Service-discovery image tag | Latest stable release (e.g. `v0.1.0`)
`sd.image.pullPolicy` | Service-discovery image pull policy | `Always`
`sd.child.enabled` | Add service-discovery sidecar container to the netdata child pod definition | `true`
`sd.child.resources` | Child service-discovery container CPU/Memory resource requests/limits | `{}`
`sd.child.configmap.name` | Child service-discovery ConfigMap name | `netdata-child-sd-config-map`
`sd.child.configmap.key` | Child service-discovery ConfigMap key | `config.yml`
`sd.child.configmap.from.file` | File to use for child service-discovery configuration generation | `sdconfig/sd-child.yml`
`sd.child.configmap.from.value` | Value to use for child service-discovery configuration generation | `{}`

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

Parameter | Description | Default
--- | --- | ---
`parent.configs.netdata` | Contents of the parent's `netdata.conf` | `memory mode = save` and `bind to = 0.0.0.0:19999`
`parent.configs.stream` | Contents of the parent's `stream.conf` | Store child data, accept all connections, and issue alarms for child data.
`parent.configs.health` | Contents of `health_alarm_notify.conf` | Email disabled, a sample of the required settings for Slack notifications
`child.configs.netdata` | Contents of the child's `netdata.conf` | No persistent storage, no alarms, no UI
`child.configs.stream` | Contents of the child `stream.conf` | Send metrics to the parent at netdata:19999
`child.configs.kubelet` | Contents of the child's `go.d/k8s_kubelet.conf` that drives the kubelet collector | Update metrics every sec, do not retry to detect the endpoint, look for the kubelet metrics at http://127.0.0.1:10255/metrics
`child.configs.kubeproxy` | Contents of the child's `go.d/k8s_kubeproxy.conf` that drives the kubeproxy collector | Update metrics every sec, do not retry to detect the endpoint, look for the coredns metrics at http://127.0.0.1:10249/metrics
 
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

Netdata's [service discovery](https://github.com/netdata/agent-service-discovery/), which is installed as part of the Helm chart installation, finds what services are running on a cluster's pods, converts that into configuration files, and exports them so they can be monitored.

Service discovery currently supports the following services via their associated collector:

-   [ActiveMQ](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/activemq)
-   [Apache](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/apache)
-   [Bind](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/bind)
-   [CockroachDB](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/cockroachdb)
-   [Consul](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/consul)
-   [CoreDNS](https://learn.netdata.cloud/docs/agent/collectors/go.d.plugin/modules/coredns)
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
