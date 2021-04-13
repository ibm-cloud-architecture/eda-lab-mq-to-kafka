# Lab to MQ to Kafka 

A hands-on lab to send sold items from different stores to MQ and then to Kafka (Confluent or Strimzi) using MQ Kafka connector.

For Strimzi deployment see [the lab description from main EDA site](https://ibm-cloud-architecture.github.io/refarch-eda/use-cases/connect-mq/).

For Confluent deployment see the next sections below.

## Audience

* Developers and architects.

## what you will learn

* Run Confluent and IBM MQ locally and test the integration from source to MQ to Kafka using Kafka MQ connector.
* Deploy the connector to OpenShift with Confluent already deployed on it

## Pre-requisites

You need the following:

* [git](https://git-scm.com/)
* [Maven 3.0 or later](https://maven.apache.org)
* Java 8 or later
* Confluent Kafka cluster deployed on OpenShift.
* IBM MQ deployed inside Cloud Pak for Integration 


Clone this repository:

```shell
git clone https://github.com/ibm-cloud-architecture/eda-lab-mq-to-kafka.git
```

## Deployment Lab

This section is using the following components to demonstrate an end to end integration between an application using JMS to MQ and then Kafka Connect and Kafka topic.

![](docs/mq-kafka-lab1.png)

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

### Get the MQ Broker credential


### Deploy the Store simulator

Define the secrets to connect to MQ Broker:

```
```

Using the kustomize extension to `oc` CLI:

```
oc apply -k kustomize/apps/store-simulator/
```

### Deploy Kafka Connect with MQ Connector

* Clone the Source and Sink connector repositories

```shell
./scripts/cloneMQConnectors.sh
```

You should get one `kafka-connect-mq-source` and `kafka-connect-mq-sink` folders.

* Build each jars file for both connectors

```shell
cd kafka-connect-mq-sink
mvn clean package
cd ../kafka-connect-mq-source
mvn clean package
```

* Modify the `mq-source.properties` under kustomize/kconnect/config to reflect the name of your brokers, channel and queues

* Deploy the connector using Confluent Connector deployment

* Modify the mq-source.json to define the connector

## For development purpose

This section is for developing the solution and not for user of the solution

## Start MQ and Confluent Kafka locally

It will also start a Kafka connector server and the Store simulator:

```shell
docker-compose up -d
```

This may take few minutes for the first run as it downloads few docker images.

Create the two Kafka topics needed for `items` and `inventory`:

```shell
./scripts/createTopics.sh
```

Access MQ console with: [https://localhost:9443/ibmmq/console](https://localhost:9443/ibmmq/console/) using admin user and default password.
The default QManager is `QM1`, the Channel is `DEV.APP.SVRCONN` and the queue is `DEV.QUEUE.1`. The channel and queue are configured to accept connection.

## Deploy the Kafka MQ Connector

Use the following command to get access the MQ Source and Sink connector projects:

```shell
./scripts/cloneMQConnectors.sh
```

Then under the source connector folder (`kafka-connect-mq-source`), build the connector using Maven:

```shell
mvn clean package
```

The jar will be something like: `/target/kafka-connect-mq-source-1.3.1-jar-with-dependencies.jar`


Got to the Control Center user interface: [](http://localhost:9021)