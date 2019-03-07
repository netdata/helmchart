# netdata
## Helm Chart `netdata`
Each **netdata** `(slave)` is able to replicate/mirror its database to another **netdata** `(master)`, by streaming collected
metrics, in real-time to it.

### netdata `(slave)`
**netdata** is installed as DaemonSet. I have set `tolerations effect: NoSchedule` in DaemonSet. In my case, I need to install `netdata` to all hosts in a cluster and get metrics.

### netdata `(master)`
**netdata** is installed as StatefulSet. 
From all **netdata** `(slave)` replicate to **netdata** `(master)` 


#### netdata.conf and stream.conf
`templates/configmap.yaml`
