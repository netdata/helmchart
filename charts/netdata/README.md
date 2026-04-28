# Netdata Helm chart for Kubernetes deployments

<a href="https://artifacthub.io/packages/search?repo=netdata" target="_blank" rel="noopener noreferrer"><img loading="lazy" src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/netdata" alt="Artifact HUB" class="img_node_modules-@docusaurus-theme-classic-lib-theme-MDXComponents-Img-styles-module"></img></a>

![Version: 3.7.165](https://img.shields.io/badge/Version-3.7.165-informational?style=flat-square)

![AppVersion: v2.10.3](https://img.shields.io/badge/AppVersion-v2.10.3-informational?style=flat-square)

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

<h3>General settings</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td>replicaCount</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of `replicas` for the parent netdata `Deployment`</td>
		</tr>
		<tr>
			<td>deploymentStrategy.type</td>
			<td>string</td>
			<td><pre lang="json">
"Recreate"
</pre>
</td>
			<td>Deployment strategy for pod deployments. Recreate is the safest value.</td>
		</tr>
		<tr>
			<td>imagePullSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>An optional list of references to secrets in the same namespace to use for pulling any of the images</td>
		</tr>
		<tr>
			<td>image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"netdata/netdata"
</pre>
</td>
			<td>Container image repository</td>
		</tr>
		<tr>
			<td>image.tag</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Chart.AppVersion }}"
</pre>
</td>
			<td>Container image tag</td>
		</tr>
		<tr>
			<td>image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"Always"
</pre>
</td>
			<td>Container image pull policy</td>
		</tr>
		<tr>
			<td>initContainersImage.repository</td>
			<td>string</td>
			<td><pre lang="json">
"alpine"
</pre>
</td>
			<td>Init containers' image repository</td>
		</tr>
		<tr>
			<td>initContainersImage.tag</td>
			<td>string</td>
			<td><pre lang="json">
"latest"
</pre>
</td>
			<td>Init containers' image tag</td>
		</tr>
		<tr>
			<td>initContainersImage.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"Always"
</pre>
</td>
			<td>Init containers' image pull policy</td>
		</tr>
		<tr>
			<td>sysctlInitContainer.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable an init container to modify Kernel settings</td>
		</tr>
		<tr>
			<td>sysctlInitContainer.command</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>sysctl init container command to execute</td>
		</tr>
		<tr>
			<td>sysctlInitContainer.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>sysctl Init container CPU/Memory resource requests/limits</td>
		</tr>
		<tr>
			<td>service.type</td>
			<td>string</td>
			<td><pre lang="json">
"ClusterIP"
</pre>
</td>
			<td>Parent service type</td>
		</tr>
		<tr>
			<td>service.port</td>
			<td>int</td>
			<td><pre lang="json">
19999
</pre>
</td>
			<td>Parent service port</td>
		</tr>
		<tr>
			<td>service.annotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations to add to the service</td>
		</tr>
		<tr>
			<td>service.loadBalancerIP</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Static LoadBalancer IP, only to be used with service type=LoadBalancer</td>
		</tr>
		<tr>
			<td>service.loadBalancerSourceRanges</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>List of allowed IPs for LoadBalancer</td>
		</tr>
		<tr>
			<td>service.externalTrafficPolicy</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Denotes if this Service desires to route external traffic to node-local or cluster-wide endpoints</td>
		</tr>
		<tr>
			<td>service.healthCheckNodePort</td>
			<td>string</td>
			<td><pre lang="json">
null
</pre>
</td>
			<td>Specifies the health check node port (only to be used with type LoadBalancer and external traffic policy Local)</td>
		</tr>
		<tr>
			<td>service.clusterIP</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Specific cluster IP when service type is cluster IP. Use `None` for headless service</td>
		</tr>
		<tr>
			<td>ingress.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Create Ingress to access the netdata web UI</td>
		</tr>
		<tr>
			<td>ingress.annotations</td>
			<td>object</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Associate annotations to the Ingress</td>
		</tr>
		<tr>
			<td>ingress.path</td>
			<td>string</td>
			<td><pre lang="json">
"/"
</pre>
</td>
			<td>URL path for the ingress. If changed, a proxy server needs to be configured in front of netdata to translate path from a custom one to a `/`</td>
		</tr>
		<tr>
			<td>ingress.pathType</td>
			<td>string</td>
			<td><pre lang="json">
"Prefix"
</pre>
</td>
			<td>pathType for your ingress controller. Default value is correct for nginx. If you use your own ingress controller, check the correct value</td>
		</tr>
		<tr>
			<td>ingress.hosts[0]</td>
			<td>string</td>
			<td><pre lang="json">
"netdata.k8s.local"
</pre>
</td>
			<td>URL hostnames for the ingress (they need to resolve to the external IP of the ingress controller)</td>
		</tr>
		<tr>
			<td>httpRoute.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Create HTTPRoute to access the netdata web UI via Gateway API</td>
		</tr>
		<tr>
			<td>httpRoute.annotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations to add to the HTTPRoute</td>
		</tr>
		<tr>
			<td>httpRoute.labels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels to add to the HTTPRoute</td>
		</tr>
		<tr>
			<td>httpRoute.parentRefs</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Parent references for Gateway API HTTPRoute. Required when `httpRoute.enabled=true`</td>
		</tr>
		<tr>
			<td>httpRoute.hostnames</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Hostnames for the HTTPRoute</td>
		</tr>
		<tr>
			<td>httpRoute.rules</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Optional explicit HTTPRoute rules. If empty, a default PathPrefix `/` rule is generated</td>
		</tr>
		<tr>
			<td>rbac.create</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>if true, create & use RBAC resources</td>
		</tr>
		<tr>
			<td>rbac.pspEnabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Specifies whether a PodSecurityPolicy should be created</td>
		</tr>
		<tr>
			<td>serviceAccount.create</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>if true, create a service account</td>
		</tr>
		<tr>
			<td>serviceAccount.name</td>
			<td>string</td>
			<td><pre lang="json">
"netdata"
</pre>
</td>
			<td>The name of the service account to use. If not set and create is true, a name is generated using the fullname template</td>
		</tr>
		<tr>
			<td>restarter.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Install CronJob to update Netdata Pods</td>
		</tr>
		<tr>
			<td>restarter.schedule</td>
			<td>string</td>
			<td><pre lang="json">
"00 06 * * *"
</pre>
</td>
			<td>The schedule in Cron format</td>
		</tr>
		<tr>
			<td>restarter.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"rancher/kubectl"
</pre>
</td>
			<td>Container image repo</td>
		</tr>
		<tr>
			<td>restarter.image.tag</td>
			<td>string</td>
			<td><pre lang="json">
".auto"
</pre>
</td>
			<td>Container image tag. If `.auto`, the image tag version of the rancher/kubectl will reflect the Kubernetes cluster version</td>
		</tr>
		<tr>
			<td>restarter.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"Always"
</pre>
</td>
			<td>Container image pull policy</td>
		</tr>
		<tr>
			<td>restarter.restartPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"Never"
</pre>
</td>
			<td>Container restart policy</td>
		</tr>
		<tr>
			<td>restarter.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Container resources</td>
		</tr>
		<tr>
			<td>restarter.concurrencyPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"Forbid"
</pre>
</td>
			<td>Specifies how to treat concurrent executions of a job</td>
		</tr>
		<tr>
			<td>restarter.startingDeadlineSeconds</td>
			<td>int</td>
			<td><pre lang="json">
60
</pre>
</td>
			<td>Optional deadline in seconds for starting the job if it misses scheduled time for any reason</td>
		</tr>
		<tr>
			<td>restarter.successfulJobsHistoryLimit</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>The number of successful finished jobs to retain</td>
		</tr>
		<tr>
			<td>restarter.failedJobsHistoryLimit</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>The number of failed finished jobs to retain</td>
		</tr>
		<tr>
			<td>notifications.slack.webhook_url</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Slack webhook URL</td>
		</tr>
		<tr>
			<td>notifications.slack.recipient</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Slack recipient list</td>
		</tr>
	</tbody>
</table>
<h3>Service Discovery</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td>sd.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"netdata/agent-sd"
</pre>
</td>
			<td>Container image repository</td>
		</tr>
		<tr>
			<td>sd.image.tag</td>
			<td>string</td>
			<td><pre lang="json">
"v0.2.10"
</pre>
</td>
			<td>Container image tag</td>
		</tr>
		<tr>
			<td>sd.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"Always"
</pre>
</td>
			<td>Container image pull policy</td>
		</tr>
		<tr>
			<td>sd.child.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Add service-discovery sidecar container to the netdata child pod definition</td>
		</tr>
		<tr>
			<td>sd.child.configmap.name</td>
			<td>string</td>
			<td><pre lang="json">
"netdata-child-sd-config-map"
</pre>
</td>
			<td>Child service-discovery ConfigMap name</td>
		</tr>
		<tr>
			<td>sd.child.configmap.key</td>
			<td>string</td>
			<td><pre lang="json">
"config.yml"
</pre>
</td>
			<td>Child service-discovery ConfigMap key</td>
		</tr>
		<tr>
			<td>sd.child.configmap.from.file</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>File to use for child service-discovery configuration generation</td>
		</tr>
		<tr>
			<td>sd.child.configmap.from.value</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Value to use for child service-discovery configuration generation</td>
		</tr>
		<tr>
			<td>sd.child.resources</td>
			<td>object</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Child service-discovery container CPU/Memory resource requests/limits</td>
		</tr>
	</tbody>
</table>
<h3>Parent</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td>parent.hostname</td>
			<td>string</td>
			<td><pre lang="json">
"netdata-parent"
</pre>
</td>
			<td>Parent node hostname</td>
		</tr>
		<tr>
			<td>parent.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Install parent Deployment to receive metrics from children nodes</td>
		</tr>
		<tr>
			<td>parent.port</td>
			<td>int</td>
			<td><pre lang="json">
19999
</pre>
</td>
			<td>Parent's listen port</td>
		</tr>
		<tr>
			<td>parent.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Resources for the parent deployment</td>
		</tr>
		<tr>
			<td>parent.livenessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
0
</pre>
</td>
			<td>Number of seconds after the container has started before liveness probes are initiated</td>
		</tr>
		<tr>
			<td>parent.livenessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container</td>
		</tr>
		<tr>
			<td>parent.livenessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>How often (in seconds) to perform the liveness probe</td>
		</tr>
		<tr>
			<td>parent.livenessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Minimum consecutive successes for the liveness probe to be considered successful after having failed</td>
		</tr>
		<tr>
			<td>parent.livenessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of seconds after which the liveness probe times out</td>
		</tr>
		<tr>
			<td>parent.readinessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
0
</pre>
</td>
			<td>Number of seconds after the container has started before readiness probes are initiated</td>
		</tr>
		<tr>
			<td>parent.readinessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready</td>
		</tr>
		<tr>
			<td>parent.readinessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>How often (in seconds) to perform the readiness probe</td>
		</tr>
		<tr>
			<td>parent.readinessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Minimum consecutive successes for the readiness probe to be considered successful after having failed</td>
		</tr>
		<tr>
			<td>parent.readinessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of seconds after which the readiness probe times out</td>
		</tr>
		<tr>
			<td>parent.securityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
201
</pre>
</td>
			<td>The UID to run the container process</td>
		</tr>
		<tr>
			<td>parent.securityContext.runAsGroup</td>
			<td>int</td>
			<td><pre lang="json">
201
</pre>
</td>
			<td>The GID to run the container process</td>
		</tr>
		<tr>
			<td>parent.securityContext.fsGroup</td>
			<td>int</td>
			<td><pre lang="json">
201
</pre>
</td>
			<td>The supplementary group for setting permissions on volumes</td>
		</tr>
		<tr>
			<td>parent.terminationGracePeriodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
300
</pre>
</td>
			<td>Duration in seconds the pod needs to terminate gracefully</td>
		</tr>
		<tr>
			<td>parent.nodeSelector</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Node selector for the parent deployment</td>
		</tr>
		<tr>
			<td>parent.tolerations</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Tolerations settings for the parent deployment</td>
		</tr>
		<tr>
			<td>parent.affinity</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Affinity settings for the parent deployment</td>
		</tr>
		<tr>
			<td>parent.priorityClassName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pod priority class name for the parent deployment</td>
		</tr>
		<tr>
			<td>parent.env</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Set environment parameters for the parent deployment</td>
		</tr>
		<tr>
			<td>parent.envFrom</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Set environment parameters for the parent deployment from ConfigMap and/or Secrets</td>
		</tr>
		<tr>
			<td>parent.podLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels to add to the parent pods</td>
		</tr>
		<tr>
			<td>parent.podAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations to add to the parent pods</td>
		</tr>
		<tr>
			<td>parent.dnsPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"Default"
</pre>
</td>
			<td>DNS policy for pod</td>
		</tr>
		<tr>
			<td>parent.database.persistence</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Whether the parent should use a persistent volume for the DB</td>
		</tr>
		<tr>
			<td>parent.database.storageclass</td>
			<td>string</td>
			<td><pre lang="json">
"-"
</pre>
</td>
			<td>The storage class for the persistent volume claim of the parent's database store, mounted to `/var/cache/netdata`</td>
		</tr>
		<tr>
			<td>parent.database.volumesize</td>
			<td>string</td>
			<td><pre lang="json">
"5Gi"
</pre>
</td>
			<td>The storage space for the PVC of the parent database</td>
		</tr>
		<tr>
			<td>parent.alarms.persistence</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Whether the parent should use a persistent volume for the alarms log</td>
		</tr>
		<tr>
			<td>parent.alarms.storageclass</td>
			<td>string</td>
			<td><pre lang="json">
"-"
</pre>
</td>
			<td>The storage class for the persistent volume claim of the parent's alarm log, mounted to `/var/lib/netdata`</td>
		</tr>
		<tr>
			<td>parent.alarms.volumesize</td>
			<td>string</td>
			<td><pre lang="json">
"1Gi"
</pre>
</td>
			<td>The storage space for the PVC of the parent alarm log</td>
		</tr>
		<tr>
			<td>parent.configs</td>
			<td>object</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Manage custom parent's configs</td>
		</tr>
		<tr>
			<td>parent.claiming.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable parent claiming for netdata cloud</td>
		</tr>
		<tr>
			<td>parent.claiming.token</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Claim token</td>
		</tr>
		<tr>
			<td>parent.claiming.rooms</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Comma separated list of claim rooms IDs. Empty value = All nodes room only</td>
		</tr>
		<tr>
			<td>parent.extraVolumeMounts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional volumeMounts to add to the parent pods</td>
		</tr>
		<tr>
			<td>parent.extraVolumes</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional volumes to add to the parent pods</td>
		</tr>
		<tr>
			<td>parent.extraInitContainers</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional init containers to add to the parent pods</td>
		</tr>
	</tbody>
</table>
<h3>Child</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td>child.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Install child DaemonSet to gather data from nodes</td>
		</tr>
		<tr>
			<td>child.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.parent.port }}"
</pre>
</td>
			<td>Children's listen port</td>
		</tr>
		<tr>
			<td>child.updateStrategy</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>An update strategy to replace existing DaemonSet pods with new pods</td>
		</tr>
		<tr>
			<td>child.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Resources for the child DaemonSet</td>
		</tr>
		<tr>
			<td>child.livenessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
0
</pre>
</td>
			<td>Number of seconds after the container has started before liveness probes are initiated</td>
		</tr>
		<tr>
			<td>child.livenessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container</td>
		</tr>
		<tr>
			<td>child.livenessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>How often (in seconds) to perform the liveness probe</td>
		</tr>
		<tr>
			<td>child.livenessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Minimum consecutive successes for the liveness probe to be considered successful after having failed</td>
		</tr>
		<tr>
			<td>child.livenessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of seconds after which the liveness probe times out</td>
		</tr>
		<tr>
			<td>child.readinessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
0
</pre>
</td>
			<td>Number of seconds after the container has started before readiness probes are initiated</td>
		</tr>
		<tr>
			<td>child.readinessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready</td>
		</tr>
		<tr>
			<td>child.readinessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>How often (in seconds) to perform the readiness probe</td>
		</tr>
		<tr>
			<td>child.readinessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Minimum consecutive successes for the readiness probe to be considered successful after having failed</td>
		</tr>
		<tr>
			<td>child.readinessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of seconds after which the readiness probe times out</td>
		</tr>
		<tr>
			<td>child.terminationGracePeriodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>Duration in seconds the pod needs to terminate gracefully</td>
		</tr>
		<tr>
			<td>child.nodeSelector</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Node selector for the child daemonsets</td>
		</tr>
		<tr>
			<td>child.tolerations</td>
			<td>list</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Tolerations settings for the child daemonsets</td>
		</tr>
		<tr>
			<td>child.affinity</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Affinity settings for the child daemonsets</td>
		</tr>
		<tr>
			<td>child.priorityClassName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pod priority class name for the child daemonsets</td>
		</tr>
		<tr>
			<td>child.podLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels to add to the child pods</td>
		</tr>
		<tr>
			<td>child.podAnnotationAppArmor.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Whether or not to include the AppArmor security annotation</td>
		</tr>
		<tr>
			<td>child.podAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations to add to the child pods</td>
		</tr>
		<tr>
			<td>child.hostNetwork</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Usage of host networking and ports</td>
		</tr>
		<tr>
			<td>child.dnsPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"ClusterFirstWithHostNet"
</pre>
</td>
			<td>DNS policy for pod. Should be `ClusterFirstWithHostNet` if `child.hostNetwork = true`</td>
		</tr>
		<tr>
			<td>child.persistence.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Whether or not to persist `/var/lib/netdata` in the `child.persistence.hostPath`</td>
		</tr>
		<tr>
			<td>child.persistence.hostPath</td>
			<td>string</td>
			<td><pre lang="json">
"/var/lib/netdata-k8s-child"
</pre>
</td>
			<td>Host node directory for storing child instance data</td>
		</tr>
		<tr>
			<td>child.podsMetadata.useKubelet</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Send requests to the Kubelet /pods endpoint instead of Kubernetes API server to get pod metadata</td>
		</tr>
		<tr>
			<td>child.podsMetadata.kubeletUrl</td>
			<td>string</td>
			<td><pre lang="json">
"https://localhost:10250"
</pre>
</td>
			<td>Kubelet URL</td>
		</tr>
		<tr>
			<td>child.configs</td>
			<td>object</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Manage custom child's configs</td>
		</tr>
		<tr>
			<td>child.env</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Set environment parameters for the child daemonset</td>
		</tr>
		<tr>
			<td>child.envFrom</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Set environment parameters for the child daemonset from ConfigMap and/or Secrets</td>
		</tr>
		<tr>
			<td>child.claiming.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable child claiming for netdata cloud</td>
		</tr>
		<tr>
			<td>child.claiming.token</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Claim token</td>
		</tr>
		<tr>
			<td>child.claiming.rooms</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Comma separated list of claim rooms IDs. Empty value = All nodes room only</td>
		</tr>
		<tr>
			<td>child.extraVolumeMounts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional volumeMounts to add to the child pods</td>
		</tr>
		<tr>
			<td>child.extraVolumes</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional volumes to add to the child pods</td>
		</tr>
	</tbody>
</table>
<h3>K8s State</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td>k8sState.hostname</td>
			<td>string</td>
			<td><pre lang="json">
"netdata-k8s-state"
</pre>
</td>
			<td>K8s state node hostname</td>
		</tr>
		<tr>
			<td>k8sState.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Install this Deployment to gather data from K8s cluster</td>
		</tr>
		<tr>
			<td>k8sState.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.parent.port }}"
</pre>
</td>
			<td>Listen port</td>
		</tr>
		<tr>
			<td>k8sState.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Compute resources required by this Deployment</td>
		</tr>
		<tr>
			<td>k8sState.livenessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
0
</pre>
</td>
			<td>Number of seconds after the container has started before liveness probes are initiated</td>
		</tr>
		<tr>
			<td>k8sState.livenessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>When a liveness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the liveness probe means restarting the container</td>
		</tr>
		<tr>
			<td>k8sState.livenessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>How often (in seconds) to perform the liveness probe</td>
		</tr>
		<tr>
			<td>k8sState.livenessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Minimum consecutive successes for the liveness probe to be considered successful after having failed</td>
		</tr>
		<tr>
			<td>k8sState.livenessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of seconds after which the liveness probe times out</td>
		</tr>
		<tr>
			<td>k8sState.readinessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
0
</pre>
</td>
			<td>Number of seconds after the container has started before readiness probes are initiated</td>
		</tr>
		<tr>
			<td>k8sState.readinessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>When a readiness probe fails, Kubernetes will try failureThreshold times before giving up. Giving up the readiness probe means marking the Pod Unready</td>
		</tr>
		<tr>
			<td>k8sState.readinessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>How often (in seconds) to perform the readiness probe</td>
		</tr>
		<tr>
			<td>k8sState.readinessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Minimum consecutive successes for the readiness probe to be considered successful after having failed</td>
		</tr>
		<tr>
			<td>k8sState.readinessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of seconds after which the readiness probe times out</td>
		</tr>
		<tr>
			<td>k8sState.terminationGracePeriodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>Duration in seconds the pod needs to terminate gracefully</td>
		</tr>
		<tr>
			<td>k8sState.nodeSelector</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Node selector</td>
		</tr>
		<tr>
			<td>k8sState.tolerations</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Tolerations settings</td>
		</tr>
		<tr>
			<td>k8sState.affinity</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Affinity settings</td>
		</tr>
		<tr>
			<td>k8sState.priorityClassName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pod priority class name</td>
		</tr>
		<tr>
			<td>k8sState.podLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels</td>
		</tr>
		<tr>
			<td>k8sState.podAnnotationAppArmor.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Whether or not to include the AppArmor security annotation</td>
		</tr>
		<tr>
			<td>k8sState.podAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations</td>
		</tr>
		<tr>
			<td>k8sState.dnsPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"ClusterFirstWithHostNet"
</pre>
</td>
			<td>DNS policy for pod</td>
		</tr>
		<tr>
			<td>k8sState.persistence.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Whether should use a persistent volume for `/var/lib/netdata`</td>
		</tr>
		<tr>
			<td>k8sState.persistence.storageclass</td>
			<td>string</td>
			<td><pre lang="json">
"-"
</pre>
</td>
			<td>The storage class for the persistent volume claim of `/var/lib/netdata`</td>
		</tr>
		<tr>
			<td>k8sState.persistence.volumesize</td>
			<td>string</td>
			<td><pre lang="json">
"1Gi"
</pre>
</td>
			<td>The storage space for the PVC of `/var/lib/netdata`</td>
		</tr>
		<tr>
			<td>k8sState.env</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Set environment parameters</td>
		</tr>
		<tr>
			<td>k8sState.envFrom</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Set environment parameters from ConfigMap and/or Secrets</td>
		</tr>
		<tr>
			<td>k8sState.configs</td>
			<td>object</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Manage custom configs</td>
		</tr>
		<tr>
			<td>k8sState.claiming.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable claiming for netdata cloud</td>
		</tr>
		<tr>
			<td>k8sState.claiming.token</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Claim token</td>
		</tr>
		<tr>
			<td>k8sState.claiming.rooms</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Comma separated list of claim rooms IDs. Empty value = All nodes room only</td>
		</tr>
		<tr>
			<td>k8sState.extraVolumeMounts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional volumeMounts to add to the k8sState pods</td>
		</tr>
		<tr>
			<td>k8sState.extraVolumes</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional volumes to add to the k8sState pods</td>
		</tr>
	</tbody>
</table>
<h3>Netdata OpenTelemetry</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td>netdataOpentelemetry.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable the Netdata OpenTelemetry Deployment</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.hostname</td>
			<td>string</td>
			<td><pre lang="json">
"netdata-otel"
</pre>
</td>
			<td>Hostname for the Netdata OpenTelemetry instance</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.parent.port }}"
</pre>
</td>
			<td>Listen port</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.service.type</td>
			<td>string</td>
			<td><pre lang="json">
"ClusterIP"
</pre>
</td>
			<td>Service type</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.service.port</td>
			<td>int</td>
			<td><pre lang="json">
4317
</pre>
</td>
			<td>Service port</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.service.annotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Service annotations</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.service.clusterIP</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Cluster IP address (only used with service.type ClusterIP)</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.service.loadBalancerIP</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>LoadBalancer IP address (only used with service.type LoadBalancer)</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.service.loadBalancerSourceRanges</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Allowed source ranges for LoadBalancer (only used with service.type LoadBalancer)</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.service.externalTrafficPolicy</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>External traffic policy (only used with service.type LoadBalancer)</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.service.healthCheckNodePort</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Health check node port (only used with service.type LoadBalancer and external traffic policy Local)</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Compute resources required by this Deployment</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.livenessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
0
</pre>
</td>
			<td>Number of seconds after the container has started before liveness probes are initiated</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.livenessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>When a liveness probe fails, Kubernetes will try failureThreshold times before giving up</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.livenessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>How often (in seconds) to perform the liveness probe</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.livenessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Minimum consecutive successes for the liveness probe to be considered successful after having failed</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.livenessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of seconds after which the liveness probe times out</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.readinessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
0
</pre>
</td>
			<td>Number of seconds after the container has started before readiness probes are initiated</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.readinessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>When a readiness probe fails, Kubernetes will try failureThreshold times before giving up</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.readinessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>How often (in seconds) to perform the readiness probe</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.readinessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Minimum consecutive successes for the readiness probe to be considered successful after having failed</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.readinessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of seconds after which the readiness probe times out</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.securityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
201
</pre>
</td>
			<td>The UID to run the container process</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.securityContext.runAsGroup</td>
			<td>int</td>
			<td><pre lang="json">
201
</pre>
</td>
			<td>The GID to run the container process</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.securityContext.fsGroup</td>
			<td>int</td>
			<td><pre lang="json">
201
</pre>
</td>
			<td>The supplementary group for setting permissions on volumes</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.terminationGracePeriodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
30
</pre>
</td>
			<td>Duration in seconds the pod needs to terminate gracefully</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.nodeSelector</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Node selector</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.tolerations</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Tolerations settings</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.affinity</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Affinity settings</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.priorityClassName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pod priority class name</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.podLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.podAnnotationAppArmor.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Whether or not to include the AppArmor security annotation</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.podAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.dnsPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"ClusterFirst"
</pre>
</td>
			<td>DNS policy for pod</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.persistence.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Whether to use persistent volumes</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.persistence.storageclass</td>
			<td>string</td>
			<td><pre lang="json">
"-"
</pre>
</td>
			<td>The storage class for the persistent volume claim (both varlib and varlog volumes)</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.persistence.volumesize</td>
			<td>string</td>
			<td><pre lang="json">
"10Gi"
</pre>
</td>
			<td>The storage space for the logs (varlog volume)</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.configs</td>
			<td>object</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Manage custom configs</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.env</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Set environment parameters</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.envFrom</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Set environment parameters from ConfigMap and/or Secrets</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.claiming.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable claiming for netdata cloud</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.claiming.token</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Claim token</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.claiming.rooms</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Comma separated list of claim rooms IDs. Empty value = All nodes room only</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.extraVolumeMounts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional volumeMounts</td>
		</tr>
		<tr>
			<td>netdataOpentelemetry.extraVolumes</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional volumes</td>
		</tr>
	</tbody>
</table>
<h3>OpenTelemetry Collector</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td>otel-collector.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Set to true to enable the OpenTelemetry Collector</td>
		</tr>
		<tr>
			<td>otel-collector.mode</td>
			<td>string</td>
			<td><pre lang="json">
"daemonset"
</pre>
</td>
			<td>Deployment mode: daemonset, deployment, or statefulset</td>
		</tr>
		<tr>
			<td>otel-collector.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"otel/opentelemetry-collector-k8s"
</pre>
</td>
			<td>Image repository</td>
		</tr>
		<tr>
			<td>otel-collector.presets.kubernetesAttributes.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable Kubernetes attributes collection</td>
		</tr>
		<tr>
			<td>otel-collector.presets.logsCollection.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable logs collection from Kubernetes pods</td>
		</tr>
		<tr>
			<td>otel-collector.presets.logsCollection.includeCollectorLogs</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Include collector logs in the collection</td>
		</tr>
		<tr>
			<td>otel-collector.config</td>
			<td>object</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>OpenTelemetry Collector configuration</td>
		</tr>
		<tr>
			<td>otel-collector.resources</td>
			<td>object</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Resources</td>
		</tr>
		<tr>
			<td>otel-collector.serviceAccount.create</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Create service account</td>
		</tr>
		<tr>
			<td>otel-collector.clusterRole.create</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Create cluster role</td>
		</tr>
		<tr>
			<td>otel-collector.clusterRole.rules</td>
			<td>list</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Cluster role rules</td>
		</tr>
		<tr>
			<td>otel-collector.tolerations</td>
			<td>list</td>
			<td><pre lang="">
See values.yaml for defaults
</pre>
</td>
			<td>Tolerations to run on all nodes</td>
		</tr>
	</tbody>
</table>

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
