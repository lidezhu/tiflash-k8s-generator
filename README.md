# The guide to build tiflash k8s cluster and test it using chaos-mesh

## Install tiflash cluster
* Generate tiflash.yaml and chaos related yaml file: `./generate-tiflash.sh [namespace] [tidb-cluster-name] [tiflash_image] [sub_dir]`
* Install tidb-cluster: 
```
cd tidb-operator/charts/tidb-cluster
helm install --values=values.yaml --name=[tidb-cluster-name] --namespace=[namespace] .
```
* Install tiflash: `kubectl apply -f [sub_dir]/tiflash.yaml`

## Using chaos-mesh to test
* `kubectl create namespace tiflash-chaos`
* `kubectl apply -f [sub_dir]/network-delay-pd-tiflash.yaml`
