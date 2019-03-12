# netdata Helm chart for kubernetes deployments

_This Helm chart for netdata was based on the work of varyumin (https://github.com/varyumin/netdata)_

** This Helm chart is in Beta. Please validate that the settings are suitable for your cluster, before using them in production **

## Helm Chart `netdata`
Each **netdata** `(slave)` is able to replicate/mirror its database to another **netdata** `(master)`, by streaming collected
metrics, in real-time to it.

### netdata `(slave)`
**netdata** is installed as DaemonSet.

### netdata `(master)` 
**netdata** is installed as StatefulSet. It makes persistent volume claims with class "standard" to store the metrics database and the alarms

The slaves are headless collectors, sending their metrics to the master. 

### netdata configuration

`templates/configmap.yaml` contains minimal master and slave configurations for netdata.conf, stream.conf and health_alarm_notify.conf. 
