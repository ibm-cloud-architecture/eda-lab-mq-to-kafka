# Lab to MQ to Kafka 

A hands-on lab to send sold item from store to MQ and then to Kafka (Confluent or Strimzi) using MQ Kafka connector.

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
* Docker engine

Clone this repository:

```shell
git clone https://github.com/ibm-cloud-architecture/eda-lab-mq-to-kafka.git
```

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