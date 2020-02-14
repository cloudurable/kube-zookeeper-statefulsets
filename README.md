# StatefulSet with ZooKeeper as an example



## Developer

To build this cluster.

#### Deploy ZooKeeper ensemble
```sh
kubectl apply -f zookeeper.yaml
```

Look up the pods in the StatefulSet.

#### See pods in this ZooKeeper cluster
```sh
kubectl get pods -lapp=zookeeper
```

#### Find out why a pod did not deploy
```sh
 kubectl describe pods zookeeper-0

```

#### Un-deploy ZooKeeper cluster
```sh
kubectl delete -f zookeeper.yaml
```

### See Logs
```sh
kubectl logs zookeeper-0
```
