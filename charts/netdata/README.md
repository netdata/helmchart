# Netdata Helm chart for Kubernetes deployments

<a href="https://artifacthub.io/packages/search?repo=netdata" target="_blank" rel="noopener noreferrer"><img loading="lazy" src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/netdata" alt="Artifact HUB" class="img_node_modules-@docusaurus-theme-classic-lib-theme-MDXComponents-Img-styles-module"></img></a>

<img src="https://img.shields.io/badge/Version-3.7.159-informational" alt="Version: 3.7.159"></img>

<img loading="lazy" src="https://img.shields.io/badge/AppVersion-v2.9.0-informational" alt="AppVersion: v2.9.0" class="img_node_modules-@docusaurus-theme-classic-lib-theme-MDXComponents-Img-styles-module"></img>

_Based on the work of varyumin (https://github.com/varyumin/netdata)_.

## Introduction

This chart bootstraps a [Netdata](https://github.com/netdata/netdata) deployment on a [Kubernetes](http://kubernetes.io)
cluster using the [Helm](https://helm.sh) package manager.

By default, the chart installs:

- A Netdata child pod on each node of a cluster, using a `Daemonset`
- A Netdata k8s state monitoring pod on one node, using a `Deployment`. This virtual node is called `netdata-k8s-state`.
- A Netdata parent pod on one node, using a `Deployment`. This virtual node is called `netdata-parent`.

Disabled by default:

- A Netdata restarter `CronJob`. Its main purpose is to automatically update Netdata when using nightly releases.

The child pods and the state pod function as headless collectors that collect and forward
all the metrics to the parent pod. The parent pod uses persistent volumes to store metrics and alarms, handle alarm
notifications, and provide the Netdata UI to view metrics using an ingress controller.

Please validate that the settings are suitable for your cluster before using them in production.

## Prerequisites

- A working cluster running Kubernetes v1.9 or newer.
- The [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) command line tool,
  within [one minor version difference](https://kubernetes.io/docs/tasks/tools/install-kubectl/#before-you-begin) of
  your cluster, on an administrative system.
- The [Helm package manager](https://helm.sh/) v3.8.0 or newer on the same administrative system.

## Required Resources and Permissions

Netdata is a comprehensive monitoring solution that requires specific access to host resources to function effectively. By design, monitoring solutions like Netdata need visibility into various system components to collect metrics and provide insights. The following mounts, privileges, and capabilities are essential for Netdata's operation, and applying restrictive security profiles or limiting these accesses may significantly impact functionality or render the monitoring solution ineffective.

<details>
<summary>See required mounts, privileges and RBAC resources</summary>

### Required Mounts

| Mount                                                      |             Type             |          Node           | Components & Descriptions                                                                                                                                                                                                                                                                                                                             |
|:-----------------------------------------------------------|:----------------------------:|:-----------------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/`                                                        |           hostPath           |          child          | •  **diskspace.plugin**: Host mount points monitoring.                                                                                                                                                                                                                                                                                                |
| `/proc`                                                    |           hostPath           |          child          | •  **proc.plugin**: Host system monitoring (CPU, memory, network interfaces, disks, etc.).                                                                                                                                                                                                                                                            |
| `/sys`                                                     |           hostPath           |          child          | •  **cgroups.plugin**: Docker containers monitoring and name resolution.                                                                                                                                                                                                                                                                              |
| `/var/log`                                                 |           hostPath           |          child          | • **systemd-journal.plugin**: Viewing, exploring and analyzing systemd journal logs.                                                                                                                                                                                                                                                                  |
| `/etc/os-release`                                          |           hostPath           | child, parent, k8sState | •  **netdata**: Host info detection.                                                                                                                                                                                                                                                                                                                  |
| `/etc/passwd`, `/etc/group`                                |           hostPath           |          child          | •  **apps.plugin**: Monitoring of host system resource usage by each user and user group.                                                                                                                                                                                                                                                             |
| `{{ .Values.child.persistence.hostPath }}/var/lib/netdata` | hostPath (DirectoryOrCreate) |          child          | •  **netdata**: Persistence of Netdata's /var/lib/netdata directory which contains netdata public unique ID and other files that should persist across container recreations. Without persistence, a new netdata unique ID is generated for each child on every container recreation, causing children to appear as new nodes on the Parent instance. |

### Required Privileges and Capabilities

| Privilege/Capability | Node  | Components & Descriptions                                                                                                                                                                                                                                                                                                                                                                      |
|:---------------------|:-----:|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Host Network Mode    | child | • **proc.plugin**: Host system networking stack monitoring. <br/>• **go.d.plugin**: Monitoring applications running on the host and inside containers. <br/>• **local-listeners**: Discovering local services/applications. Map open (listening) ports to running services/applications. <br/>• **network-viewer.plugin**: Discovering all current network sockets and building a network-map. |
| Host PID Mode        | child | • **cgroups.plugin**: Container network interfaces monitoring. Map virtual interfaces in the system namespace to interfaces inside containers.                                                                                                                                                                                                                                                 |
| SYS_ADMIN            | child | • **cgroups.plugin**: Container network interfaces monitoring. Map virtual interfaces in the system namespace to interfaces inside containers. <br/>• **network-viewer.plugin**: Discovering all current network sockets and building a network-map.                                                                                                                                           |
| SYS_PTRACE           | child | • **local-listeners**: Discovering local services/applications. Map open (listening) ports to running services/applications.                                                                                                                                                                                                                                                                   |

### Required Kubernetes RBAC Resources

| Resource           | Verbs            | Components & Descriptions                                                                                                                                                        |
|:-------------------|:-----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| pods               | get, list, watch | • **service discovery**: Used for discovering services. <br/>• **go.d/k8s_state**: Kubernetes state monitoring. <br/>• **netdata**: Used by cgroup-name.sh and get-kubernetes-labels.sh scripts. |
| services           | get, list, watch | • **service discovery**: Used for discovering services.                                                                                                                          |
| configmaps         | get, list, watch | • **service discovery**: Used for discovering services.                                                                                                                          |
| secrets            | get, list, watch | • **service discovery**: Used for discovering services.                                                                                                                          |
| nodes              | get, list, watch | • **go.d/k8s_state**: Kubernetes state monitoring.                                                                                                                               |
| nodes/metrics      | get, list, watch | • **go.d/k8s_kubelet**: Used when querying Kubelet HTTPS endpoint.                                                                                                               |
| nodes/proxy        | get, list, watch | • **netdata**: Used by cgroup-name.sh when querying Kubelet /pods endpoint.                                                                                                      |
| deployments (apps) | get, list, watch | • **go.d/k8s_state**: Kubernetes state monitoring.                                                                                                                               |
| cronjobs (batch)   | get, list, watch | • **go.d/k8s_state**: Kubernetes state monitoring.                                                                                                                               |
| jobs (batch)       | get, list, watch | • **go.d/k8s_state**: Kubernetes state monitoring.                                                                                                                               |
| namespaces         | get              | • **go.d/k8s_state**: Kubernetes state monitoring. <br/>• **netdata**: Used by cgroup-name.sh and get-kubernetes-labels.sh scripts.                                              |

</details>

## Installing the Helm chart

You can install the Helm chart via our Helm repository, or by cloning this repository.

### Installing via our Helm repository (recommended)

To use Netdata's Helm repository, run the following commands:

```bash
helm repo add netdata https://netdata.github.io/helmchart/
helm install netdata netdata/netdata
```

**See our [install Netdata on Kubernetes](https://github.com/netdata/netdata/blob/master/packaging/installer/methods/kubernetes.md)
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

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
 helm delete netdata
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the netdata chart and their default values.

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Number of `replicas` for the parent netdata `Deployment` |
| deploymentStrategy | object | `{"type":"Recreate"}` | Deployment strategy for pod deployments. Recreate is the safest value. |
| imagePullSecrets | list | `[]` | An optional list of references to secrets in the same namespace to use for pulling any of the images |
| image.repository | string | `"netdata/netdata"` | Container image repository |
| image.tag | string | `"{{ .Chart.AppVersion }}"` | Container image tag |
| image.pullPolicy | string | `"Always"` | Container image pull policy |
| initContainersImage.repository | string | `"alpine"` | Init containers' image repository |
| initContainersImage.tag | string | `"latest"` | Init containers' image tag |
| initContainersImage.pullPolicy | string | `"Always"` | Init containers' image pull policy |
| sysctlInitContainer.enabled | bool | `false` | Enable an init container to modify Kernel settings |
| sysctlInitContainer.command | list | `[]` | sysctl init container command to execute |
| sysctlInitContainer.resources | object | `{}` | sysctl Init container CPU/Memory resource requests/limits |
| service.type | string | `"ClusterIP"` | Parent service type |
| service.port | int | `19999` | Parent service port |
| service.annotations | object | `{}` | Additional annotations to add to the service |
| service.loadBalancerIP | string | `""` | Static LoadBalancer IP, only to be used with service type=LoadBalancer |
| service.loadBalancerSourceRanges | list | `[]` | List of allowed IPs for LoadBalancer |
| service.externalTrafficPolicy | string | `""` | Denotes if this Service desires to route external traffic to node-local or cluster-wide endpoints |
| service.healthCheckNodePort | string | `nil` | Specifies the health check node port (only to be used with type LoadBalancer and external traffic policy Local) |
| service.clusterIP | string | `""` | Specific cluster IP when service type is cluster IP. Use `None` for headless service |
| ingress.enabled | bool | `true` | Create Ingress to access the netdata web UI |
| ingress.annotations | object | `{"kubernetes.io/ingress.class":"nginx","kubernetes.io/tls-acme":"true"}` | Associate annotations to the Ingress |
| ingress.path | string | `"/"` | URL path for the ingress. If changed, a proxy server needs to be configured in front of netdata to translate path from a custom one to a `/` |
| ingress.pathType | string | `"Prefix"` | pathType for your ingress controller. Default value is correct for nginx. If you use your own ingress controller, check the correct value |
| ingress.hosts | list | `["netdata.k8s.local"]` | URL hostnames for the ingress (they need to resolve to the external IP of the ingress controller) |
| rbac.create | bool | `true` | if true, create & use RBAC resources |
| rbac.pspEnabled | bool | `true` | Specifies whether a PodSecurityPolicy should be created |
| serviceAccount.create | bool | `true` | if true, create a service account |
| serviceAccount.name | string | `"netdata"` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| restarter.enabled | bool | `false` | Install CronJob to update Netdata Pods |
| restarter.schedule | string | `"00 06 * * *"` | The schedule in Cron format |
| restarter.image.repository | string | `"rancher/kubectl"` | Container image repo |
| restarter.image.tag | string | `".auto"` | Container image tag. If `.auto`, the image tag version of the rancher/kubectl will reflect the Kubernetes cluster version |
| restarter.image.pullPolicy | string | `"Always"` | Container image pull policy |
| restarter.restartPolicy | string | `"Never"` | Container restart policy |
| restarter.resources | object | `{}` | Container resources |
| restarter.concurrencyPolicy | string | `"Forbid"` | Specifies how to treat concurrent executions of a job |
| restarter.startingDeadlineSeconds | int | `60` | Optional deadline in seconds for starting the job if it misses scheduled time for any reason |
| restarter.successfulJobsHistoryLimit | int | `3` | The number of successful finished jobs to retain |
| restarter.failedJobsHistoryLimit | int | `3` | The number of failed finished jobs to retain |
| notifications.slack.webhook_url | string | `""` | Slack webhook URL |
| notifications.slack.recipient | string | `""` | Slack recipient list |

### Service Discovery

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| sd.image.repository | string | `"netdata/agent-sd"` | Container image repository |
| sd.image.tag | string | `"v0.2.10"` | Container image tag |
| sd.image.pullPolicy | string | `"Always"` | Container image pull policy |
| sd.child.enabled | bool | `true` | Add service-discovery sidecar container to the netdata child pod definition |
| sd.child.configmap.name | string | `"netdata-child-sd-config-map"` | Child service-discovery ConfigMap name |
| sd.child.configmap.key | string | `"config.yml"` | Child service-discovery ConfigMap key |
| sd.child.configmap.from.file | string | `""` | File to use for child service-discovery configuration generation |
| sd.child.configmap.from.value | object | `{}` | Value to use for child service-discovery configuration generation |
| sd.child.resources | object | `{"limits":{"cpu":"50m","memory":"150Mi"},"requests":{"cpu":"50m","memory":"100Mi"}}` | Child service-discovery container CPU/Memory resource requests/limits |

### Parent

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| parent.hostname | string | `"netdata-parent"` | Parent node hostname |
| parent.enabled | bool | `true` | Install parent Deployment to receive metrics from children nodes |
| parent.port | int | `19999` | Parent's listen port |
| parent.resources | object | `{}` | Resources for the parent deployment |
| parent.livenessProbe.initialDelaySeconds | int | `0` | Number of seconds after the container has started before liveness probes are initiated |
| parent.livenessProbe.failureThreshold | int | `3` | When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container |
| parent.livenessProbe.periodSeconds | int | `30` | How often (in seconds) to perform the liveness probe |
| parent.livenessProbe.successThreshold | int | `1` | Minimum consecutive successes for the liveness probe to be considered successful after having failed |
| parent.livenessProbe.timeoutSeconds | int | `1` | Number of seconds after which the liveness probe times out |
| parent.readinessProbe.initialDelaySeconds | int | `0` | Number of seconds after the container has started before readiness probes are initiated |
| parent.readinessProbe.failureThreshold | int | `3` | When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready |
| parent.readinessProbe.periodSeconds | int | `30` | How often (in seconds) to perform the readiness probe |
| parent.readinessProbe.successThreshold | int | `1` | Minimum consecutive successes for the readiness probe to be considered successful after having failed |
| parent.readinessProbe.timeoutSeconds | int | `1` | Number of seconds after which the readiness probe times out |
| parent.securityContext.runAsUser | int | `201` | The UID to run the container process |
| parent.securityContext.runAsGroup | int | `201` | The GID to run the container process |
| parent.securityContext.fsGroup | int | `201` | The supplementary group for setting permissions on volumes |
| parent.terminationGracePeriodSeconds | int | `300` | Duration in seconds the pod needs to terminate gracefully |
| parent.nodeSelector | object | `{}` | Node selector for the parent deployment |
| parent.tolerations | list | `[]` | Tolerations settings for the parent deployment |
| parent.affinity | object | `{}` | Affinity settings for the parent deployment |
| parent.priorityClassName | string | `""` | Pod priority class name for the parent deployment |
| parent.env | object | `{}` | Set environment parameters for the parent deployment |
| parent.envFrom | list | `[]` | Set environment parameters for the parent deployment from ConfigMap and/or Secrets |
| parent.podLabels | object | `{}` | Additional labels to add to the parent pods |
| parent.podAnnotations | object | `{}` | Additional annotations to add to the parent pods |
| parent.dnsPolicy | string | `"Default"` | DNS policy for pod |
| parent.database.persistence | bool | `true` | Whether the parent should use a persistent volume for the DB |
| parent.database.storageclass | string | `"-"` | The storage class for the persistent volume claim of the parent's database store, mounted to `/var/cache/netdata` |
| parent.database.volumesize | string | `"5Gi"` | The storage space for the PVC of the parent database |
| parent.alarms.persistence | bool | `true` | Whether the parent should use a persistent volume for the alarms log |
| parent.alarms.storageclass | string | `"-"` | The storage class for the persistent volume claim of the parent's alarm log, mounted to `/var/lib/netdata` |
| parent.alarms.volumesize | string | `"1Gi"` | The storage space for the PVC of the parent alarm log |
| parent.configs | object | See values.yaml for default configuration | Manage custom parent's configs |
| parent.claiming.enabled | bool | `false` | Enable parent claiming for netdata cloud |
| parent.claiming.token | string | `""` | Claim token |
| parent.claiming.rooms | string | `""` | Comma separated list of claim rooms IDs. Empty value = All nodes room only |
| parent.extraVolumeMounts | list | `[]` | Additional volumeMounts to add to the parent pods |
| parent.extraVolumes | list | `[]` | Additional volumes to add to the parent pods |
| parent.extraInitContainers | list | `[]` | Additional init containers to add to the parent pods |

### Child

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| child.enabled | bool | `true` | Install child DaemonSet to gather data from nodes |
| child.port | string | `"{{ .Values.parent.port }}"` | Children's listen port |
| child.updateStrategy | object | `{}` | An update strategy to replace existing DaemonSet pods with new pods |
| child.resources | object | `{}` | Resources for the child DaemonSet |
| child.livenessProbe.initialDelaySeconds | int | `0` | Number of seconds after the container has started before liveness probes are initiated |
| child.livenessProbe.failureThreshold | int | `3` | When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container |
| child.livenessProbe.successThreshold | int | `1` | Minimum consecutive successes for the liveness probe to be considered successful after having failed |
| child.livenessProbe.timeoutSeconds | int | `1` | Number of seconds after which the liveness probe times out |
| child.readinessProbe.initialDelaySeconds | int | `0` | Number of seconds after the container has started before readiness probes are initiated |
| child.readinessProbe.failureThreshold | int | `3` | When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready |
| child.readinessProbe.periodSeconds | int | `30` | How often (in seconds) to perform the readiness probe |
| child.readinessProbe.successThreshold | int | `1` | Minimum consecutive successes for the readiness probe to be considered successful after having failed |
| child.readinessProbe.timeoutSeconds | int | `1` | Number of seconds after which the readiness probe times out |
| child.terminationGracePeriodSeconds | int | `30` | Duration in seconds the pod needs to terminate gracefully |
| child.nodeSelector | object | `{}` | Node selector for the child daemonsets |
| child.tolerations | list | `[{"effect":"NoSchedule","operator":"Exists"}]` | Tolerations settings for the child daemonsets |
| child.affinity | object | `{}` | Affinity settings for the child daemonsets |
| child.priorityClassName | string | `""` | Pod priority class name for the child daemonsets |
| child.podLabels | object | `{}` | Additional labels to add to the child pods |
| child.podAnnotationAppArmor.enabled | bool | `true` | Whether or not to include the AppArmor security annotation |
| child.podAnnotations | object | `{}` | Additional annotations to add to the child pods |
| child.hostNetwork | bool | `true` | Usage of host networking and ports |
| child.dnsPolicy | string | `"ClusterFirstWithHostNet"` | DNS policy for pod. Should be `ClusterFirstWithHostNet` if `child.hostNetwork = true` |
| child.persistence.enabled | bool | `true` | Whether or not to persist `/var/lib/netdata` in the `child.persistence.hostPath` |
| child.persistence.hostPath | string | `"/var/lib/netdata-k8s-child"` | Host node directory for storing child instance data |
| child.podsMetadata.useKubelet | bool | `false` | Send requests to the Kubelet /pods endpoint instead of Kubernetes API server to get pod metadata |
| child.podsMetadata.kubeletUrl | string | `"https://localhost:10250"` | Kubelet URL |
| child.configs | object | See values.yaml for default configuration | Manage custom child's configs |
| child.env | object | `{}` | Set environment parameters for the child daemonset |
| child.envFrom | list | `[]` | Set environment parameters for the child daemonset from ConfigMap and/or Secrets |
| child.claiming.enabled | bool | `false` | Enable child claiming for netdata cloud |
| child.claiming.token | string | `""` | Claim token |
| child.claiming.rooms | string | `""` | Comma separated list of claim rooms IDs. Empty value = All nodes room only |
| child.extraVolumeMounts | list | `[]` | Additional volumeMounts to add to the child pods |
| child.extraVolumes | list | `[]` | Additional volumes to add to the child pods |

### Child1.0

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| child.livenessProbe.periodSeconds | int | `30` | How often (in seconds) to perform the liveness probe |

### K8s State

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| k8sState.hostname | string | `"netdata-k8s-state"` | K8s state node hostname |
| k8sState.enabled | bool | `true` | Install this Deployment to gather data from K8s cluster |
| k8sState.port | string | `"{{ .Values.parent.port }}"` | Listen port |
| k8sState.resources | object | `{}` | Compute resources required by this Deployment |
| k8sState.livenessProbe.initialDelaySeconds | int | `0` | Number of seconds after the container has started before liveness probes are initiated |
| k8sState.livenessProbe.failureThreshold | int | `3` | When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container |
| k8sState.livenessProbe.periodSeconds | int | `30` | How often (in seconds) to perform the liveness probe |
| k8sState.livenessProbe.successThreshold | int | `1` | Minimum consecutive successes for the liveness probe to be considered successful after having failed |
| k8sState.livenessProbe.timeoutSeconds | int | `1` | Number of seconds after which the liveness probe times out |
| k8sState.readinessProbe.initialDelaySeconds | int | `0` | Number of seconds after the container has started before readiness probes are initiated |
| k8sState.readinessProbe.failureThreshold | int | `3` | When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready |
| k8sState.readinessProbe.periodSeconds | int | `30` | How often (in seconds) to perform the readiness probe |
| k8sState.readinessProbe.successThreshold | int | `1` | Minimum consecutive successes for the readiness probe to be considered successful after having failed |
| k8sState.readinessProbe.timeoutSeconds | int | `1` | Number of seconds after which the readiness probe times out |
| k8sState.terminationGracePeriodSeconds | int | `30` | Duration in seconds the pod needs to terminate gracefully |
| k8sState.nodeSelector | object | `{}` | Node selector |
| k8sState.tolerations | list | `[]` | Tolerations settings |
| k8sState.affinity | object | `{}` | Affinity settings |
| k8sState.priorityClassName | string | `""` | Pod priority class name |
| k8sState.podLabels | object | `{}` | Additional labels |
| k8sState.podAnnotationAppArmor.enabled | bool | `true` | Whether or not to include the AppArmor security annotation |
| k8sState.podAnnotations | object | `{}` | Additional annotations |
| k8sState.dnsPolicy | string | `"ClusterFirstWithHostNet"` | DNS policy for pod |
| k8sState.persistence.enabled | bool | `true` | Whether should use a persistent volume for `/var/lib/netdata` |
| k8sState.persistence.storageclass | string | `"-"` | The storage class for the persistent volume claim of `/var/lib/netdata` |
| k8sState.persistence.volumesize | string | `"1Gi"` | The storage space for the PVC of `/var/lib/netdata` |
| k8sState.env | object | `{}` | Set environment parameters |
| k8sState.envFrom | list | `[]` | Set environment parameters from ConfigMap and/or Secrets |
| k8sState.configs | object | See values.yaml for default configuration | Manage custom configs |
| k8sState.claiming.enabled | bool | `false` | Enable claiming for netdata cloud |
| k8sState.claiming.token | string | `""` | Claim token |
| k8sState.claiming.rooms | string | `""` | Comma separated list of claim rooms IDs. Empty value = All nodes room only |
| k8sState.extraVolumeMounts | list | `[]` | Additional volumeMounts to add to the k8sState pods |
| k8sState.extraVolumes | list | `[]` | Additional volumes to add to the k8sState pods |

### Netdata OpenTelemetry

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| netdataOpentelemetry.enabled | bool | `false` | Enable the Netdata OpenTelemetry Deployment |
| netdataOpentelemetry.hostname | string | `"netdata-otel"` | Hostname for the Netdata OpenTelemetry instance |
| netdataOpentelemetry.port | string | `"{{ .Values.parent.port }}"` | Listen port |
| netdataOpentelemetry.service.type | string | `"ClusterIP"` | Service type |
| netdataOpentelemetry.service.port | int | `4317` | Service port |
| netdataOpentelemetry.service.annotations | object | `{}` | Service annotations |
| netdataOpentelemetry.resources | object | `{}` | Compute resources required by this Deployment |
| netdataOpentelemetry.livenessProbe.initialDelaySeconds | int | `0` | Number of seconds after the container has started before liveness probes are initiated |
| netdataOpentelemetry.livenessProbe.failureThreshold | int | `3` | When a liveness probe fails, Kubernetes will try failureThreshold times before giving up |
| netdataOpentelemetry.livenessProbe.periodSeconds | int | `30` | How often (in seconds) to perform the liveness probe |
| netdataOpentelemetry.livenessProbe.successThreshold | int | `1` | Minimum consecutive successes for the liveness probe to be considered successful after having failed |
| netdataOpentelemetry.livenessProbe.timeoutSeconds | int | `1` | Number of seconds after which the liveness probe times out |
| netdataOpentelemetry.readinessProbe.initialDelaySeconds | int | `0` | Number of seconds after the container has started before readiness probes are initiated |
| netdataOpentelemetry.readinessProbe.failureThreshold | int | `3` | When a readiness probe fails, Kubernetes will try failureThreshold times before giving up |
| netdataOpentelemetry.readinessProbe.periodSeconds | int | `30` | How often (in seconds) to perform the readiness probe |
| netdataOpentelemetry.readinessProbe.successThreshold | int | `1` | Minimum consecutive successes for the readiness probe to be considered successful after having failed |
| netdataOpentelemetry.readinessProbe.timeoutSeconds | int | `1` | Number of seconds after which the readiness probe times out |
| netdataOpentelemetry.terminationGracePeriodSeconds | int | `30` | Duration in seconds the pod needs to terminate gracefully |
| netdataOpentelemetry.nodeSelector | object | `{}` | Node selector |
| netdataOpentelemetry.tolerations | list | `[]` | Tolerations settings |
| netdataOpentelemetry.affinity | object | `{}` | Affinity settings |
| netdataOpentelemetry.priorityClassName | string | `""` | Pod priority class name |
| netdataOpentelemetry.podLabels | object | `{}` | Additional labels |
| netdataOpentelemetry.podAnnotationAppArmor.enabled | bool | `true` | Whether or not to include the AppArmor security annotation |
| netdataOpentelemetry.podAnnotations | object | `{}` | Additional annotations |
| netdataOpentelemetry.dnsPolicy | string | `"Default"` | DNS policy for pod |
| netdataOpentelemetry.persistence.enabled | bool | `true` | Whether should use a persistent volume |
| netdataOpentelemetry.persistence.storageclass | string | `"-"` | The storage class for the persistent volume claim |
| netdataOpentelemetry.persistence.volumesize | string | `"10Gi"` | The storage space for the PVC |
| netdataOpentelemetry.configs | object | See values.yaml for default configuration | Manage custom configs |
| netdataOpentelemetry.env | object | `{}` | Set environment parameters |
| netdataOpentelemetry.envFrom | list | `[]` | Set environment parameters from ConfigMap and/or Secrets |
| netdataOpentelemetry.claiming.enabled | bool | `false` | Enable claiming for netdata cloud |
| netdataOpentelemetry.claiming.token | string | `""` | Claim token |
| netdataOpentelemetry.claiming.rooms | string | `""` | Comma separated list of claim rooms IDs. Empty value = All nodes room only |
| netdataOpentelemetry.extraVolumeMounts | list | `[]` | Additional volumeMounts |
| netdataOpentelemetry.extraVolumes | list | `[]` | Additional volumes |

### OpenTelemetry Collector

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| otel-collector.enabled | bool | `false` | Set to true to enable the OpenTelemetry Collector |
| otel-collector.mode | string | `"daemonset"` | Deployment mode: daemonset, deployment, or statefulset |
| otel-collector.image.repository | string | `"otel/opentelemetry-collector-k8s"` | Image repository |
| otel-collector.presets.kubernetesAttributes.enabled | bool | `true` | Enable Kubernetes attributes collection |
| otel-collector.presets.logsCollection.enabled | bool | `true` | Enable logs collection from Kubernetes pods |
| otel-collector.presets.logsCollection.includeCollectorLogs | bool | `false` | Include collector logs in the collection |
| otel-collector.config | object | `{"exporters":{"otlp":{"endpoint":"{{ .Release.Name }}-otel:4317","retry_on_failure":{"enabled":true,"initial_interval":"5s","max_elapsed_time":"300s","max_interval":"30s"},"sending_queue":{"enabled":true,"num_consumers":10,"queue_size":1000},"tls":{"insecure":true}}},"processors":{"batch":{"send_batch_max_size":1500,"send_batch_size":1000,"timeout":"10s"},"k8sattributes":{"auth_type":"serviceAccount","extract":{"annotations":[{"from":"pod","key":"app","tag_name":"annotation.app"}],"labels":[{"from":"pod","key":"app","tag_name":"app"},{"from":"pod","key":"component","tag_name":"component"}],"metadata":["k8s.namespace.name","k8s.deployment.name","k8s.statefulset.name","k8s.daemonset.name","k8s.cronjob.name","k8s.job.name","k8s.node.name","k8s.pod.name","k8s.pod.uid","k8s.pod.start_time","k8s.container.name"]},"passthrough":false,"pod_association":[{"sources":[{"from":"resource_attribute","name":"k8s.pod.ip"}]},{"sources":[{"from":"resource_attribute","name":"k8s.pod.uid"}]},{"sources":[{"from":"connection"}]}]},"memory_limiter":{"check_interval":"5s","limit_percentage":80,"spike_limit_percentage":25},"resourcedetection":{"detectors":["env","system"],"timeout":"5s"}},"receivers":{"filelog":{"exclude":["/var/log/pods/*/otc-container/*.log"],"include":["/var/log/pods/*/*/*.log"],"include_file_name":false,"include_file_path":true,"operators":[{"id":"container-parser","max_log_size":102400,"type":"container"}],"start_at":"end"}},"service":{"pipelines":{"logs":{"exporters":["otlp"],"processors":["memory_limiter","k8sattributes","resourcedetection","batch"],"receivers":["filelog"]}}}}` | OpenTelemetry Collector configuration |
| otel-collector.resources | object | `{"limits":{"cpu":"200m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resources |
| otel-collector.serviceAccount.create | bool | `true` | Create service account |
| otel-collector.clusterRole.create | bool | `true` | Create cluster role |
| otel-collector.clusterRole.rules | list | `[{"apiGroups":[""],"resources":["pods","namespaces","nodes"],"verbs":["get","list","watch"]},{"apiGroups":["apps"],"resources":["replicasets"],"verbs":["get","list","watch"]}]` | Cluster role rules |
| otel-collector.tolerations | list | `[{"effect":"NoSchedule","operator":"Exists"},{"effect":"NoExecute","operator":"Exists"}]` | Tolerations to run on all nodes |
| otel-collector.ports.otlp.enabled | bool | `true` | Enable OTLP port |
| otel-collector.ports.otlp-http.enabled | bool | `true` | Enable OTLP HTTP port |
| otel-collector.ports.metrics.enabled | bool | `true` | Enable metrics port |

Example to set the parameters from the command line:

```console
$ helm install ./netdata --name my-release \
    --set notifications.slack.webhook_url=MySlackAPIURL \
    --set notifications.slack.recipient="@MyUser MyChannel"
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

> **Tip**: You can use the default values.yaml

> **Note:**: To opt out of anonymous statistics, set the `DO_NOT_TRACK`
> environment variable to non-zero or non-empty value in
`parent.env` / `child.env` configuration (e.g.,: `DO_NOT_TRACK: 1`)
> or uncomment the line in `values.yml`.

### Configuration files

| Parameter                         | Description                                                                           | Default                                                                                                                       |
|-----------------------------------|---------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| `parent.configs.netdata`          | Contents of the parent's `netdata.conf`                                               | `memory mode = dbengine`                                                                                                      |
| `parent.configs.stream`           | Contents of the parent's `stream.conf`                                                | Store child data, accept all connections, and issue alarms for child data.                                                    |
| `parent.configs.health`           | Contents of `health_alarm_notify.conf`                                                | Email disabled, a sample of the required settings for Slack notifications                                                     |
| `parent.configs.exporting`        | Contents of `exporting.conf`                                                          | Disabled                                                                                                                      |
| `k8sState.configs.netdata`        | Contents of  `netdata.conf`                                                           | No persistent storage, no alarms                                                                                              |
| `k8sState.configs.stream`         | Contents of `stream.conf`                                                             | Send metrics to the parent at netdata:{{ service.port }}                                                                      |
| `k8sState.configs.exporting`      | Contents of `exporting.conf`                                                          | Disabled                                                                                                                      |
| `k8sState.configs.go.d`           | Contents of `go.d.conf`                                                               | Only k8s_state enabled                                                                                                        |
| `k8sState.configs.go.d-k8s_state` | Contents of `go.d/k8s_state.conf`                                                     | k8s_state configuration                                                                                                       |
| `child.configs.netdata`           | Contents of the child's `netdata.conf`                                                | No persistent storage, no alarms, no UI                                                                                       |
| `child.configs.stream`            | Contents of the child's `stream.conf`                                                 | Send metrics to the parent at netdata:{{ service.port }}                                                                      |
| `child.configs.exporting`         | Contents of the child's `exporting.conf`                                              | Disabled                                                                                                                      |
| `child.configs.kubelet`           | Contents of the child's `go.d/k8s_kubelet.conf` that drives the kubelet collector     | Update metrics every sec, do not retry to detect the endpoint, look for the kubelet metrics at http://127.0.0.1:10255/metrics |
| `child.configs.kubeproxy`         | Contents of the child's `go.d/k8s_kubeproxy.conf` that drives the kubeproxy collector | Update metrics every sec, do not retry to detect the endpoint, look for the coredns metrics at http://127.0.0.1:10249/metrics |

To deploy additional netdata user configuration files, you will need to add similar entries to either
the `parent.configs` or the `child.configs` arrays. Regardless of whether you add config files that reside directly
under `/etc/netdata` or in a subdirectory such as `/etc/netdata/go.d`, you can use the already provided configurations
as reference. For reference, the `parent.configs` the array includes an `example` alarm that would get triggered if the
python.d `example` module was enabled. Whenever you pass the sensitive data to your configuration like the database
credential, you can take an option to put it into the Kubernetes Secret by specifying `storedType: secret` in the
selected configuration. By default, all the configurations will be placed in the Kubernetes configmap.

Note that in this chart's default configuration, the parent performs the health checks and triggers alarms but collects little data. As a result, the only other configuration files that might make sense to add to the parent are
the alarm and alarm template definitions, under `/etc/netdata/health.d`.

> **Tip**: Do pay attention to the indentation of the config file contents, as it matters for the parsing of the `yaml` file. Note that the first line under `var: |`
> must be indented with two more spaces relative to the preceding line:

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
in: `/var/lib/netdata`. You can disable it, but this option is pretty much required in a real life scenario, as without
it each pod deletion will result in a new replication node for a parent.

### Service discovery and supported services

Netdata's [service discovery](https://github.com/netdata/agent-service-discovery/), which is installed as part of the
Helm chart installation, finds what services are running on a cluster's pods, converts that into configuration files,
and exports them, so they can be monitored.

#### Applications

Service discovery currently supports the following applications via their associated collector:

- [ActiveMQ](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/activemq/README.md)
- [Apache](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/apache/README.md)
- [Bind](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/bind/README.md)
- [CockroachDB](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/cockroachdb/README.md)
- [Consul](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/consul/README.md)
- [CoreDNS](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/coredns/README.md)
- [Elasticsearch](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/elasticsearch/README.md)
- [Fluentd](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/fluentd/README.md)
- [FreeRADIUS](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/freeradius/README.md)
- [HDFS](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/hdfs/README.md)
- [Lighttpd](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/lighttpd/README.md)
- [Logstash](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/logstash/README.md)
- [MySQL](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/mysql/README.md)
- [NGINX](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/nginx/README.md)
- [OpenVPN](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/openvpn/README.md)
- [PHP-FPM](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/phpfpm/README.md)
- [RabbitMQ](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/rabbitmq/README.md)
- [Tengine](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/tengine/README.md)
- [Unbound](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/unbound/README.md)
- [VerneMQ](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/vernemq/README.md)
- [ZooKeeper](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/zookeeper/README.md)

#### Prometheus endpoints

Service discovery supports Prometheus endpoints via
the [Prometheus](https://github.com/netdata/netdata/blob/master/src/go/plugin/go.d/collector/prometheus/README.md) collector.

Annotations on pods allow a fine control of the scraping process:

- `prometheus.io/scrape`: The default configuration will scrape all pods and, if set to false, this annotation excludes
  the pod from the scraping process.
- `prometheus.io/path`: If the metrics path is not _/metrics_, define it with this annotation.
- `prometheus.io/port`: Scrape the pod on the indicated port instead of the pod's declared ports.

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

If you want to contribute, we're humbled!

- Take a look at our [Contributing Guidelines](https://github.com/netdata/.github/blob/main/CONTRIBUTING.md).
- This repository is under the [Netdata Code Of Conduct](https://github.com/netdata/.github/blob/main/CODE_OF_CONDUCT.md).
- Chat about your contribution and let us help you in
  our [forum](https://community.netdata.cloud/c/agent-development/9)!
