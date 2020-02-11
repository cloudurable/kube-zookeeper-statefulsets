# kafka-zookeeper-statefulsets

#### Run zookeeper yaml file

```sh
kubectl apply -f zookeeper.yaml
```


#### Get statefulsets for Zookeeper

```sh
kubectl get statefulsets
NAME        READY   AGE
zookeeper   0/3     5m5s

```

#### Check Get Pods
```sh
kubectl get pods

# OUTPUT
NAME          READY   STATUS    RESTARTS   AGE
zookeeper-0   0/1     Running   2          3m14s
```

#### See the Persistent Volumes
```sh
kubectl get pv

# OUTPUT
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                                 STORAGECLASS   REASON   AGE
pv0001   100Gi      RWO,ROX,RWX    Recycle          Bound       openshift-image-registry/crc-image-registry-storage                           37d
...
pv0030   100Gi      RWO,ROX,RWX    Recycle          Bound       default/datadir-zookeeper-0                                                   37d
```
#### See the Persistent Volumes
```sh
kubectl get pvc

# OUTPUT
NAME                             STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
datadir-zookeeper-0              Bound    pv0030   100Gi      RWO,ROX,RWX                   2m10s
```

#### Describe Zookeeper

```sh
kubectl describe pod zookeeper-0

# OUTPUT
...
Type     Reason            Age                     From                         Message
----     ------            ----                    ----                         -------
Warning  FailedScheduling  7m53s                   default-scheduler            pod has unbound immediate PersistentVolumeClaims
Normal   Scheduled         7m53s                   default-scheduler            Successfully assigned default/zookeeper-0 to crc-k4zmd-master-0
Normal   Pulling           6m36s (x4 over 7m45s)   kubelet, crc-k4zmd-master-0  Pulling image "cloudurable/kube-zookeeper:0.0.1"
Normal   Pulled            6m35s (x4 over 7m28s)   kubelet, crc-k4zmd-master-0  Successfully pulled image "cloudurable/kube-zookeeper:0.0.1"
Normal   Created           6m34s (x4 over 7m27s)   kubelet, crc-k4zmd-master-0  Created container kubernetes-zookeeper
Normal   Started           6m34s (x4 over 7m27s)   kubelet, crc-k4zmd-master-0  Started container kubernetes-zookeeper
Warning  BackOff           2m39s (x26 over 7m24s)  kubelet, crc-k4zmd-master-0  Back-off restarting failed container
```

Once you run describe you will see that the deployment is failing.

To see why, let's checkout the logs for zookeeper-0.

#### Error we found

```sh
kubectl logs  --follow zookeeper-0

# OUTPUT
clientPort=2181
dataDir=/var/lib/zookeeper/data
...
Creating ZooKeeper log4j configuration
mkdir: cannot create directory '/var/lib/zookeeper': Permission denied
chown: cannot access '/var/lib/zookeeper/data': Permission denied
mkdir: cannot create directory '/var/lib/zookeeper': Permission denied
chown: invalid group: 'zookeeper:USER'
/usr/bin/start.sh: line 161: /var/lib/zookeeper/data/myid: Permission denied
```

#### Init containers


### Connecting to instance to debug
```sh
kubectl  exec -it zookeeper-0 bash

## Then run
echo "Are you ok? $(echo ruok | nc 127.0.0.1 2181)"
```
#### Grab metrics
```sh
kubectl  exec -it zookeeper-0 metrics.sh 2181

```

#### Remove Zookeeper
```sh
kubectl delete -f zookeeper.yaml
```
