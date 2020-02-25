# Kubernetes StatefulSet with ZooKeeper using Kustomize to target multiple environments

## Background

ZooKeeper is a nice tool to start StatefulSets with because it is small and lightweight,
yet exhibits a lot of the same needs as many disturbed, stateful, clustered applications.


This is part 3. In part 1 of this tutorial, we got an example of a ZooKeeper StatefulSet running locally with [minkube](https://kubernetes.io/docs/tasks/tools/install-minikube/). In part 2, we got the same application running under Red Hat OSE CRC.

This really builds on the last two tutorial and uses Kustomize to target multiple deployment environments. You could probably skip tutorial 2 and this one would still make sense.

Please refer to the
* [first tutorial](https://github.com/cloudurable/kube-zookeeper-statefulsets/wiki/Tutorial-Part-1:--Managing-Kubernetes-StatefulSets-using-ZooKeeper-and-Minikube) and
* [second tutorial](https://github.com/cloudurable/kube-zookeeper-statefulsets/wiki/Tutorial-Part-1:--Managing-Kubernetes-StatefulSets-using-ZooKeeper-and-Minikube)


As stated before, I base this tutorial from the one on the Kubernetes site on ZooKeeper and StatefulSet
but I am going to deploy to MiniKube, local Open Shift, and KIND as well as add support for Kustomize and a lot more.

I have a similar version of this Kubernetes ZooKeeper deploy working on a multi-node shared,
 corporate locked-down environment. This is a new version based on the example.

In past tutorials, I simulated some of the problems that I ran into and hope it helps.


If for some reason you would like more background on this tutorial series - [background](https://github.com/cloudurable/kube-zookeeper-statefulsets/wiki/Tutorial-Part-1:--Managing-Kubernetes-StatefulSets-using-ZooKeeper-and-Minikube#background).


> BTW, This is not my first rodeo with [ZooKeeper](https://github.com/cloudurable/zookeeper-cloud) or [Kafka](https://github.com/cloudurable/kafka-cloud) or even [deploying stateful clustered services (cassandra)](https://github.com/cloudurable/cassandra-image)
  or [managing them](https://www.linkedin.com/pulse/spark-cluster-metrics-influxdb-rick-hightower/) or setting up [KPIs](https://github.com/cloudurable/spark-cluster), but this is the first time I wrote about doing it with Kubernetes. I have also written [leadership election libs](https://github.com/advantageous/elekt) and have done [clustering](https://github.com/advantageous/qbit) with tools like ZooKeeper, namely, etcd and [Consul](https://github.com/advantageous/elekt-consul).


## Objectives

After this tutorial, you will know the following.

  * How to deploy a ZooKeeper ensemble to multiple environments using Kustomize
  * How to create base configs
  * How to create overlays.




Later follow on tutorials might show:
  * How to write deploy scripts with Helm 3 to target local vs. remote deployments
  * How to write deploy scripts with Helm 3 to target local vs. remote deployments
  * How to create your metrics gatherers and use them with Prometheus
  * How to install Kafka on top of ZooKeeper

____

## Before you begin
Before starting this tutorial, you should be familiar with the following Kubernetes concepts.

* Pods
* Cluster DNS
* Headless Services
* PersistentVolumes
* PersistentVolume Provisioning
* StatefulSets
* PodDisruptionBudgets
* PodAntiAffinity
* kubectl CLI

Recall that the tutorial on the Kubernetes site required a cluster with at least four nodes (with 2 CPUs and 4 GiB of memory), this one will work with local Kubernetes dev environments, namely, Open Shift CRC and MiniKube. This tutorial will show how to use [Kustomize](https://kustomize.io/) to target local dev and a real cluster.

___

## Use Kustomize to deploy our ZooKeeper StatefulSet to multiple environments

To target multiple environments we will use Kubernetes Kustomize.

Kustomize is built into Kubernetes. It is the default way to target multiple deployment environments.

Kustomize is a template-free way to customize Kubernetes object files by using overlays and [directives](https://kubectl.docs.kubernetes.io/pages/reference/kustomize.html) called transformers, meta sources, and generators.

In this tutorial we will use:
* bases
* commonLabels
* patchesStrategicMerge


The `bases` is path list which consists of: directories, URL or git referring to kustomization.yamls.
You can think of `bases` similar to a base image in a Dockerfile (using FROM) or a parent pom in maven or a
base class. From this `bases` you can transform and add additional details. This allows you to layer config and override config declared in the base.
In our example, we will extend the base first for `dev` then later for `dev-3` and `prod`. Let's look a the directory structure.

## Where to find the code
You can find the code for this project at:
* [Kustomize](https://github.com/cloudurable/kube-zookeeper-statefulsets/tree/kustomize) - branch that split up the manifest into multiple deployment environments.


#### Directory structure with base and overlay.

```sh

├── README.md
├── base
│   ├── kustomization.yml
│   └── zookeeper.yml
├── container
│   ├── Dockerfile
│   ├── README.md
│   ├── build.sh
│   ├── scripts
│   │   ├── metrics.sh
│   │   ├── ready_live.sh
│   │   └── start.sh
│   └── util
│       ├── debug.sh
│       ├── ...
└── overlays
    ├── dev
    │   ├── kustomization.yml
    │   └── zookeeper-dev.yml
    ├── dev-3
    │   ├── kustomization.yml
    │   └── zookeeper-dev3.yml
    └── prod
        ├── kustomization.yml
        └── zookeeper-prod.yml
```

Notice we have an `overlays` directory and a `base` directory.
The base directory will look a lot like our `zookeeper.yml` manifest file from the last two tutorials.
The `overlays` directory has a directory per target environment, namely, `prod`, `dev` and `dev-3`.
Then you can split the data specific to production (`prod`) or lightweight `dev` or our `dev-3` (dev but running three zookeeper instances in the ensemble).


#### Bases and overlays for this tutorial

```
+---------------+            +---------------------+      +-------------------+
|               |  overrides |                     |  ovr |                   |
|  base         +----------->+    overlay/dev      +------> overlay/dev-3     |
|               |            |                     |      |                   |
+--------+------+            +---------------------+      +-------------------+
         |
         |
         |
         |                           +----------------------+
         |         overrides         |                      |
         +-------------------------->+    overlay/prod      |
                                     |                      |
                                     +----------------------+

```



## Base Directory

This is a simple example so we just have two files in our `base` directory.

```
├── base
    ├── kustomization.yml
    └── zookeeper.yml
```

#### base/kustomization.yml - kustomize manifest file for base directory  

```yaml

resources:
- zookeeper.yml

commonLabels:
  app: zookeeper

```

The `kustomization.yml` file is the manifest file for ***kustomize***.  The directive `resources: - zookeeper.yml` is specifying the yaml file, which looks a lot like the last one from the last tutorial. The `commonLabels: app: zookeeper` is specifying common labels and selectors so you don't have to repeat the same labels over and over.

The `commonLabels` sets labels on all kube objects. The `commonLabels` are applied both to label selector fields and label fields.

The `zookeeper.yaml` file is just like before except there is nothing specific to `prod` or `dev` and there are no labels because we supplied them with `commonLabels` already.

#### base/zookeeper.yml - zookeeper manifest with no labels
```yaml
apiVersion: v1
kind: Service
metadata:
  name: zookeeper-headless
spec:
  ports:
  - port: 2888
    name: server
  - port: 3888
    name: leader-election
  clusterIP: None
---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper-service
spec:
  ports:
  - port: 2181
    name: client
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: zookeeper-pdb
spec:
  maxUnavailable: 1
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zookeeper
spec:
  serviceName: zookeeper-headless
  replicas: 1
  updateStrategy:
    type: RollingUpdate
  podManagementPolicy: OrderedReady
  template:
    spec:
      containers:
      - name: kubernetes-zookeeper
        imagePullPolicy: Always
        image: "cloudurable/kube-zookeeper:0.0.4"
        resources:
          requests:
            memory: "500Mi"
            cpu: "0.25"
        ports:
        - containerPort: 2181
          name: client
        - containerPort: 2888
          name: server
        - containerPort: 3888
          name: leader-election
        command:
        - sh
        - -c
        - "start.sh --servers=3 "
        readinessProbe:
          exec:
            command:
            - sh
            - -c
            - "ready_live.sh 2181"
          initialDelaySeconds: 10
          timeoutSeconds: 5
        livenessProbe:
          exec:
            command:
            - sh
            - -c
            - "ready_live.sh 2181"
          initialDelaySeconds: 10
          timeoutSeconds: 5
        volumeMounts:
        - name: datadir
          mountPath: /var/lib/zookeeper
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      initContainers:
        - name: init-zoo
          command: 
            - chown 
            - -R 
            - 1000:1000
            - /var/lib/zookeeper 
          image: ubuntu:18.04
          imagePullPolicy: Always 
          resources: {} 
          securityContext: 
            runAsUser: 0 
          terminationMessagePath: /dev/termination-log 
          terminationMessagePolicy: File 
          volumeMounts: 
          - name: datadir
            mountPath: /var/lib/zookeeper

  volumeClaimTemplates:
  - metadata:
      name: datadir
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi

```

The `commonLabels` is a `kustomize` transform as it transforms the ZooKeeper Kubernetes
and adds labels and match labels to resources. This transform gets rid of a lot of duplicate code.

Now we want to base another config based on this base. It is like we inherit all of the settings and just override the ones that we want. Let's first do this with dev.

## Dev Directory

```sh
└── overlays
    └─── dev
        ├── kustomization.yml
        └── zookeeper-dev.yml
```

You want to override the replicas and set it to 1 so we save memory when we run this on our laptop.
You want to use the pod affinity `preferredDuringSchedulingIgnoredDuringExecution` so that we can run this
on a local dev Kubernetes cluster that only has one node. You also want to change the command that starts up zookeeper to specify the number of servers in the ensemble, e.g., `command: ... start.sh --servers=1`. Lastly,
you want to run with less memory and less CPU so it fits nicely on our laptop.

To do this we will specify a yaml file with just the things we want to override and then specify that in the `kustomization.yml` manifest file we want to merge/patch using this file by using `patchesStrategicMerge:` and `bases:`. This is another transformation. This time against the output of the `base` manifest.

#### dev/kustomization.yml - kustomize manifest used to override base
```yaml
bases:
- ../../base/

patchesStrategicMerge:
- zookeeper-dev.yml

commonLabels:
  deployment-env: dev

```

Notice that `bases` specifies the base yaml file from before. Then `patchesStrategicMerge` specifies a yaml file with just the parts that you want to override. We go ahead and add a `dev` label.


The `patchesStrategicMerge` applies patches to the matching Kube object (it matches by Group/Version/Kind + Name/Namespace). The patch file you specify is `zookeeper-dev.yml` and it contains just the config definitions that you want to override. This keeps files for an environment small as the environment specific file just overrides
the parts that are different.

Let's look at the bits that we override.

#### dev/zookeeper-dev.yml - dev file used to override base
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zookeeper
spec:
  replicas: 1
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: "app"
                      operator: In
                      values:
                      - zookeeper
                topologyKey: "kubernetes.io/hostname"
      containers:
      - name: kubernetes-zookeeper
        command:
          - sh
          - -c
          - "start.sh --servers=1 "
        resources:
          requests:
            memory: "250Mi"
            cpu: "0.12"

```


Notice we added dev labels to everything, just in case we want to deploy another version at the same time in the same namespace and to show we used the correct manifest.

You don't have to extend just a base image, you can base and overlay on another overlay.

To deploy this run the following:

#### Deploy dev
```sh

# kubectl delete -f zookeeper.yaml from the other branch
kubectl apply -k overlay/dev

```

The -k option is for Kustomize. You specify the directory of the config that you want to run, which
is usually an overlay directory because bases don't usually deploy.

Now would be a good time to refer to the first tutorial and test the ZooKeeper instance (perhaps read and write a key).

### Can you overlay and overlay?

Can you overlay and overlay?

For example, let's say we ran into an issue that we can not easily reproduce and we think it is because we use three zookeeper instances in the integration environment but the only one when we are testing locally so you decide to create an overlay that has three images that run locally on your laptop cluster to closer mimic integration.  We call this environment `dev-3` because we are not very creative.


## Dev 3 for testing with ZooKeeper for three node ensemble

You decide to create an overlay that has three images that run locally on your laptop cluster to closer mimic integration to chase down a bug.  The files are laid out similar to before.  

```sh
    ├── dev-3
    │   ├── kustomization.yml
    │   └── zookeeper-dev3.yml
```

The manifest file will overlay the `dev` environment, and override the number of replicas as well as passing
the replica count to the `start.sh` script of the container.

#### dev-3/kustomization.yaml
```yaml
bases:
- ../dev/

patchesStrategicMerge:
- zookeeper-dev3.yml

```

Noice the `base` refers to `../dev/` (AKA `overlay/dev`) so you can see
that this overlay is just overriding values from `overlay/dev` like affinity `preferredDuringSchedulingIgnoredDuringExecution` so we can still run on a dev cluster.


#### dev-3/zookeeper-dev3.yml
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zookeeper
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: kubernetes-zookeeper
        command:
          - sh
          - -c
          - "start.sh --servers=3"

```

The above just overrides the number of `servers` passed to `start.sh` and the number of `replicas`.

#### Deploy dev 3
```sh

# kubectl delete -k overlay/dev if you want first or not
kubectl apply -k overlay/dev-3

```

The main reason we did not specify affinity in the very base manifest for ZooKeeper is
`kustomize` does not allow us to remove YAML attributes. It only allows us to add.
To add `requiredDuringSchedulingIgnoredDuringExecution` if `preferredDuringSchedulingIgnoredDuringExecution`
was in the base would require that we remove an attribute. If you need to add / remove attributes
based on logic, then you will need a template language like the one that ships with Helm which is
a subject of a future tutorial for sure. :)



## Prod directory

The `prod` directory is our fictitious production environment for ZooKeeper.
It is laid out much like `dev` or `dev-3`. Like `dev` its base is the `base` directory.

```sh

    └── prod
        ├── kustomization.yml
        └── zookeeper-prod.yml
```


Notice like `dev` that `bases` specifies the base directory which contains the base ZooKeeper manifest.
Also like before `patchesStrategicMerge` specifies a yaml file with just the parts
that you want to override for production. You of course want to go ahead and add a `production` label.


Recall that the `patchesStrategicMerge` applies  patches to the matching Kube object (matched by Group/Version/Kind + Name/Namespace). The patch file you specify is `zookeeper-prod.yml` and it contains just the config definitions that you want to override for production.

#### prod/kustomization.yaml - kustomize manifest file for prod
```sh
bases:
- ../../base/

patchesStrategicMerge:
- zookeeper-prod.yml

commonLabels:
  deployment-env: production

```

Now you just specify the correct affinity for prod and goose up the memory and CPU for the pods.

#### prod/zookeeper-prod.yaml
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zookeeper
spec:
  replicas: 3
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: "app"
                    operator: In
                    values:
                    - zookeeper
              topologyKey: "kubernetes.io/hostname"
      containers:
      - name: kubernetes-zookeeper
        resources:
          requests:
            memory: "500Mi"
            cpu: "0.5"

```

Notice that this is specifies `requiredDuringSchedulingIgnoredDuringExecution`
It also specifies more RAM and CPU per node as well as bumping
up the ZooKeeper ensemble count to three.

#### Deploy prod
```sh

# kubectl delete -k overlay/dev-3 if you want first or not
kubectl apply -k overlay/prod

```

Notice that prod won't run unless you have multiple kubernetes workers so don't be surprised.
After, just go back to dev.

#### Go back to dev
```sh

kubectl delete -k overlay/prod
kubectl apply -k overlay/dev

```


## Conclusion

In this tutorial, you created three overlays and on base config directory.
The dev and prod overlays used the base dir base.
The dev-3 directory used the dev directory as its base.
The overlay directories inherit attributes from their parents (bases).
The overlay directories can override or add attributes from its parent.
The directive `patchesStrategicMerge` is used to override attributes from a base set of config.
 The directive `commonLabels` is used to transform resources by adding `labels` to resources and `select` `matches`.


 Kustomize is a template-free way to customize Kubernetes object files by using overlays and [directives](https://kubectl.docs.kubernetes.io/pages/reference/kustomize.html) called transformers, meta sources, and generators.
 Kustomize is simpler to use than a full-blown template engine like Helm and allows you
 to have multiple deployment environments from the same base manifest files.


#### Bases and overlays for this tutorial

```
+---------------+            +---------------------+      +-------------------+
|               |  overrides |                     |  ovr |                   |
|  base         +----------->+    overlay/dev      +------> overlay/dev-3     |
|               |            |                     |      |                   |
+--------+------+            +---------------------+      +-------------------+
         |
         |
         |
         |                           +----------------------+
         |         overrides         |                      |
         +-------------------------->+    overlay/prod      |
                                     |                      |
                                     +----------------------+

```
