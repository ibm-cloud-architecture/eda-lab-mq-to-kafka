# Lab to MQ to Kafka

A hands-on lab series to demonstrate end-to-end integration between a JMS application using JMS to MQ and then Kafka Connect and Kafka topics, sending sold item data from different stores to MQ and Kafka using an MQ Kafka connectors.

For Strimzi deployment see [the lab description from main EDA site](https://ibm-cloud-architecture.github.io/refarch-eda/use-cases/connect-mq/).

For Confluent deployment, see the next sections below.

## Audience

* Developers and architects.

## What you will learn

* **[Lab 1:](#lab-1---run-locally-with-docker-compose)** Run Confluent and IBM MQ locally and test the integration between MQ queues and Kafka topics using the Confluent Kafka MQ connectors.
* **[Lab 2:](#lab-2---run-on-openshift-container-platform)** Deploy the connector scenario to an OpenShift cluster with Confluent Platform and IBM MQ already deployed.

![](docs/mq-kafka-lab1.png)

## Lab 1 - Run locally with docker-compose

### Pre-requisites

You will need the following:

* [git](https://git-scm.com/)
* [docker-compose](https://docs.docker.com/compose/install/)

### Scenario walkthrough

This lab scenario utilizes the officially supported IBM MQ connectors from Confluent, [IBM MQ Source Connector](https://www.confluent.io/hub/confluentinc/kafka-connect-ibmmq) and [IBM MQ Sink Connector](https://www.confluent.io/hub/confluentinc/kafka-connect-ibmmq-sink). Both of these connectors require the IBM MQ client jar (`com.ibm.mq.allclient.jar`) to be downloaded separately and included with any runtime deployments. This is covered below.

1. Clone this repository:
    ```bash
    git clone https://github.com/ibm-cloud-architecture/eda-lab-mq-to-kafka.git
    cd eda-lab-mq-to-kafka
    ```

1. Download the `confluentinc-kafka-connect-ibmmq-11.0.2.zip` file from https://www.confluent.io/hub/confluentinc/kafka-connect-ibmmq and copy the expanded contents (the entire `confluentinc-kafka-connect-ibmmq-11.0.2` folder) to `./data/connect-jars`:
    ```bash
    # Manually download the file from https://www.confluent.io/hub/confluentinc/kafka-connect-ibmmq
    unzip ~/Downloads/confluentinc-kafka-connect-ibmmq-11.0.2 -d ./data/connect-jars/
    ```

1.  Download the required IBM MQ client jars:
    ```bash
    curl -s https://repo1.maven.org/maven2/com/ibm/mq/com.ibm.mq.allclient/9.2.2.0/com.ibm.mq.allclient-9.2.2.0.jar -o com.ibm.mq.allclient-9.2.2.0.jar
    cp com.ibm.mq.allclient-9.2.2.0.jar data/connect-jars/confluentinc-kafka-connect-ibmmq-11.0.2/lib/.
    ```

1. Start the containers locally by launching the `docker-compose` stack:
    ```bash
    docker-compose up -d
    ```

1. Wait for the MQ Queue Manager to successfully start:
    ```bash
    docker logs -f ibmmq
    # Wait for the following lines:
    #   xyzZ Started web server
    #   xyzZ AMQ5041I: The queue manager task 'AUTOCONFIG' has ended. [CommentInsert1(AUTOCONFIG)]
    ```

1. Access the Store Simulator web application via [http://localhost:8080/#/simulator](http://localhost:8080/#/simulator).
    1. Under the Simulator tab, select **IBMMQ** as the backend, any number of events you wish to simulate, and click the **Simulate** button.

1. Access the IBM MQ Console via [https://localhost:9443](https://localhost:9443).
    1.  Login using the default admin credentials of `admin`/`passw0rd` and accepting any security warnings for self-signed certificate usage.
    1. Navigate to **QM1** management screen via the **Manage QM1** tile.
    1. Click on the **DEV.QUEUE.1** queue to view the simulated messages from the Store Simulator.

1. Configure the Kafka Connector instance via the Kafka Connect REST API
    ```bash
    curl -i -X PUT -H  "Content-Type:application/json" \
        http://localhost:8083/connectors/eda-store-source/config \
        -d @kustomize/environment/kconnect/config/mq-confluent-source.json
    ```

    You should receive a response similar to the following:
    ```bash
    HTTP/1.1 201 Created
    Date: Tue, 13 Apr 2021 18:16:50 GMT
    Location: http://localhost:8083/connectors/eda-store-source
    Content-Type: application/json
    Content-Length: 634
    Server: Jetty(9.4.24.v20191120)

    {"name":"eda-store-source","config":{"connector.class":"io.confluent.connect.ibm.mq.IbmMQSourceConnector","tasks.max":"1","key.converter":"org.apache.kafka.connect.storage.StringConverter","value.converter":"org.apache.kafka.connect.json.JsonConverter","mq.hostname":"ibmmq","mq.port":"1414","mq.transport.type":"client","mq.queue.manager":"QM1","mq.channel":"DEV.APP.SVRCONN","mq.username":"app","mq.password":"adummypasswordusedlocally","jms.destination.name":"DEV.QUEUE.1","jms.destination.type":"QUEUE","kafka.topic":"items","confluent.topic.bootstrap.servers":"broker:29092","name":"eda-store-source"},"tasks":[],"type":"source"}
    ```
    For more details on the Kafka Connect REST API, you can visit the [Confluent Docs](https://docs.confluent.io/platform/current/connect/references/restapi.html). This step can also be performed via the [Confluent Control Center UI](https://docs.confluent.io/platform/current/control-center/connect.html).

1. Access Confluent Control Center via [http://localhost:9021](http://localhost:9021). _(**NOTE:** This component sleeps for two minutes upon initial startup.)_
    1. Click on your active cluster
    1. Click on **Connect** in the left-nav menu, then `connect` in the Connect Cluster list.
    1. You should see your `Running` **eda-store-source** connector.
    1. Click on **Topics** in the left-nav menu and select `items` in the Topics list.
    1. Click on the **Messages** tab and enter `0` in the _Offset_ textbox.
    1. You should see all the messages that were previously in your `DEV.QUEUE.1` queue now in your `items` topic and they are no longer in the MQ queue!

1. To stop the environment once you are complete:
  ```bash
  docker-compose down
  ```


## Lab 2 - Run on OpenShift Container Platform

**UNDER CONSTRUCTION**

### Pre-requisites

You need the following:

* [git](https://git-scm.com/)
* [oc CLI](#tbd) - TODO
* [openssl](#tbd) - TODO
* Confluent Platform (Kafka cluster) deployed on Red Hat OpenShift
* IBM MQ Operator on Red Hat OpenShift

### Scenario walkthrough

#### Create custom Kafka Connect container images

1. Clone this repository:
    ```bash
    git clone https://github.com/ibm-cloud-architecture/eda-lab-mq-to-kafka.git
    cd eda-lab-mq-to-kafka
    ```

* TODO Explain what is being created.

* `oc create istag cp-init-container-operator:6.1.1.0 --from-image=confluentinc/cp-init-container-operator:6.1.1.0 --reference-policy=local`
* `oc create istag cp-server-connect-operator:6.1.1.0 --from-image=confluentinc/cp-server-connect-operator:6.1.1.0 --reference-policy=local`
* `oc apply -f custom-connect-images/build-config.yaml`
* `oc logs -f buildconfig/confluent-connect-mq`

#### Update Confluent Platform container deployments

> The assumption is made that Confluent Platform is deployed via https://github.ibm.com/ben-cornwell/confluent-operator, which deploys Confluent Schema Registry, Replicator, Connect, and Control Center as one Helm release. This is problematic when following Step 5 of the [Deploy Confluent Connectors](https://docs.confluent.io/operator/current/co-management.html#deploy-confluent-connectors) instructions, as the image registries required cannot be mixed between different components in the same release. Connect requires the internal OpenShift registry for our custom images we just created, while the other components still require the original docker.io registry.

> If Confluent Platform was deployed via the instructions available at https://docs.confluent.io/operator/current/co-deployment.html and Connect is available as it's own Helm release (ie `helm get notes connectors`), you can follow the instructions in Step 5 of the [Deploy Confluent Connectors](https://docs.confluent.io/operator/current/co-management.html#deploy-confluent-connectors) instructions to update the Confluent custom resources via the operator.

* TODO Explain what needs to updated.
> spec.cloud.docker_repo = image-registry.openshift-image-registry.svc:5000
> spec.common.container.image = ___LOCAL_PROJECT___/cp-server-connect-operator:6.1.1.0-custom-mq
> spec.common.init_containers[0].image = ___LOCAL_PROJECT___/cp-init-container-operator:6.1.1.0

*  `oc patch psc/connectors --type merge --patch "$(cat confluent-connectors-psc-patch.yaml | sed "s/___LOCAL_PROJECT___/$(oc project -q)/g")"`

* Log in to Confluent Control Center and navigate to Cluster > {cluster name} > Connect > {connect cluster name} > **Add connector** and verify that the **IbmMqSinkConnector** and **IbmMQSourceConnector** are now available as connector options.

#### Deploy MQ queue manager with remote access enabled

* TODO Create queue manager via https://www.ibm.com/docs/en/ibm-mq/9.2?topic=manager-example-configuring-tls

* From the root directory of the repository...

* Create certs:
```bash
openssl req -newkey rsa:2048 -nodes  -subj "/CN=localhost" -x509 -days 3650 -keyout  ./kustomize/environment/mq/base/certificates/tls.key -out ./kustomize/environment/mq/base/certificates/tls.crt
```

* Create client truststore:
```bash
keytool -keystore /Users/osowski/projects/eda/eda-lab-mq-to-kafka/kustomize/environment/mq/base/certificates/mq-tls.jks -import -file /Users/osowski/projects/eda/eda-lab-mq-to-kafka/kustomize/environment/mq/base/certificates/tls.crt -storepass my-mq-password -noprompt -keyalg RSA -storetype JKS
```

* TODO OTHER Kustomize UPDATES
  * Queue Manager name (affects qm)
  * Channel name (affects configmap/route)
  * Queue name (affects configmap)

* Apply Kustomize YAMLs:
```bash
oc apply -k kustomize/environment/mq
```

* TODO (optional) mq client app validation via container

#### Deploy Store Simulator application

* Apply Kustomize YAMLs:
```bash
oc apply -k kustomize/apps/store-simulator
```

#### Configure MQ Connector

* TODO

#### Verify end-to-end connectivity

* TODO

---
---
---

# OLD MATERIAL

---
---
---

### Get Kafka Confluent access credentials

Clients internal to the Kubernetes or OpenShift cluster which Confluent Platform is deployed to, most often use the following configurations:

```
bootstrap.servers=kafka.{namespace}.svc.cluster.local:9071
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="{USERNAME}" password="{PASSWORD}";
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
```

To get the SASL user and password get the secrets and search for the kafka-apikeys, then use the following commands:

```shell
# username
USERNAME=$(oc get secret kafka-apikeys -o jsonpath='{.data.global_sasl_plain_username}'} | base64 --decode | awk '{split($0,a,"="); print a[2]}')
PASSWORD=$(oc get secret kafka-apikeys -o jsonpath='{.data.global_sasl_plain_password}' | base64 --decode | awk '{split($0,a,"="); print a[2]}')
```

or create a secret using

```shell
./scripts/createJaasSecret.sh
```

### Deploy the Store simulator

Define the secrets to connect to MQ Broker:

Using the kustomize extension to `oc` CLI:

```
oc apply -k kustomize/apps/store-simulator/
```

* Modify the `mq-source.properties` under kustomize/kconnect/config to reflect the name of your brokers, channel and queues

The default QManager is `QM1`, the Channel is `DEV.APP.SVRCONN` and the queue is `DEV.QUEUE.1`. The channel and queue are configured to accept connection.
