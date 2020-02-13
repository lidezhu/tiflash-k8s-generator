# The guide to build tiflash k8s cluster and test it using chaos-mesh

## Install tiflash cluster
* Generate cluster and chaos related yaml file: `./generate-tiflash.sh namespace [tiflash_image] [tidb-cluster-name] [sub_dir] [chaos_namespace] [storage_class_name]`(Caution: pick unique namespace and don't include words [tidb/pd/tikv] in cluster name)
* Install tidb and tiflash cluster: 
```
cd [sub_dir]
./k8s.sh apply
```

## Prepare
If you want to run io chaos experiment on the cluster, you must run `./prepare_io_chaos.sh` before start the cluster.

## Manipulate tiflash cluster
* `./k8s.sh delete [true/false]` delete cluster (true means clear cluster's data, the default is true)
* `./k8s.sh clear` clear cluster data
* `./k8s.sh show` show cluster pod
* `./k8s.sh desc [pd/tikv/tidb/tiflash] [pod-num]` describe pod status
* `./k8s.sh log [pd/tikv/tidb/tiflash] [pod-num]` show logs of specific pod
* `./k8s.sh copy [pd/tikv/tidb/tiflash] [pod-num] [container file path] [host file path]` copy file from container to host
* `./k8s.sh exec [pd/tikv/tidb/tiflash] [pod-num]` attach to a specific pod
* `./k8s.sh port [pd/tidb] [host-port]` port forward host-port to a specific service port

## Run schrodinger test
* `./k8s.sh apply [bank/bank2/crud/ledger/sqllogic/ddl]` run schrodinger test
* `./k8s.sh delete [bank/bank2/crud/ledger/sqllogic/ddl]` delete schrodinger test
* `./k8s.sh log [bank/bank2/crud/ledger/sqllogic/ddl]` show schrodinger test log
* `./k8s.sh show` run schrodinger test

## Using chaos-mesh to test
* `./chaos.sh apply [kill/failure/delay_pd/delay_tikv/partition_pd/partition_tikv/delay/errno/mixed]` apply a specific chaos experiment
* `./chaos.sh show` show all chaos experiment
* `./chaos.sh delete [kill/failure/delay_pd/delay_tikv/partition_pd/partition_tikv/delay/errno/mixed]` delete a specific chaos experiment
