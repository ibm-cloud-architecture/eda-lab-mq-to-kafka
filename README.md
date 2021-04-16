
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

**Lab contents:**
1. [Pre-requisites](#pre-requisites-1)
1. [Scenario walkthrough](#scenario-walkthrough-1)
1. [Deploy MQ queue manager with remote access enabled](#deploy-mq-queue-manager-with-remote-access-enabled)
1. [Deploy Store Simulator application](#deploy-store-simulator-application)
1. [Create custom Kafka Connect container images](#create-custom-kafka-connect-container-images)
1. [Update Confluent Platform container deployments](#update-confluent-platform-container-deployments)
1. [Configure MQ Connector](#configure-mq-connector)
1. [Verify end-to-end connectivity](#verify-end-to-end-connectivity)
1. [Lab complete!](#lab-complete)

### Pre-requisites

You need the following:

* [git](https://git-scm.com/)
* [jq](https://stedolan.github.io/jq/)
* [OpenShift oc CLI](https://docs.openshift.com/container-platform/4.5/cli_reference/openshift_cli/getting-started-cli.html)
* _openssl_ & _keytool_ - Installed as part of your Linux/Mac OS X-based operating system and Java JVM respectively.
* Confluent Platform (Kafka cluster) deployed on Red Hat OpenShift via [Confluent Operator](https://docs.confluent.io/operator/current/overview.html)
* IBM MQ Operator on Red Hat OpenShift


### Scenario walkthrough

1. Clone this repository. All subsequent commands are run from the root directory of the cloned repository.
    ```bash
    git clone https://github.com/ibm-cloud-architecture/eda-lab-mq-to-kafka.git
    cd eda-lab-mq-to-kafka
    ```

1. The lab setup can be run with any number of projects between the three logical components below. Update the environment variables below with your respective projects for each component and the instructions listed below will always reference the correct project to run the commands against. All three of these values below can be the same value if all components are installed into a single project.
    ```bash
    export PROJECT_CONFLUENT_PLATFORM=my-confluent-platform-project
    export PROJECT_MQ=my-ibm-mq-project
    export PROJECT_STORE_SIMULATOR=my-store-simulator-project
    ```


#### Deploy MQ queue manager with remote access enabled

IBM MQ queue managers that are exposed by a Route on OpenShift require TLS-enabled security, so we will first create a SSL certificate pair and truststore for both queue manager and client use, respectively.

1. Create TLS certificate and key for use by the MQ QueueManager custom resource:
   ```bash
   openssl req -newkey rsa:2048 -nodes  -subj "/CN=localhost" -x509 -days 3650 \
               -keyout  ./kustomize/environment/mq/base/certificates/tls.key   \
               -out ./kustomize/environment/mq/base/certificates/tls.crt
   ```

1. Create TLS client truststore for use by the Store Simulator and Kafka Connect applications:
   ```bash
   keytool -import -keystore ./kustomize/environment/mq/base/certificates/mq-tls.jks \
           -file ./kustomize/environment/mq/base/certificates/tls.crt                \
           -storepass my-mq-password -noprompt -keyalg RSA -storetype JKS
   ```

1. Create the OpenShift resources by applying the Kustomize YAMLs:
   ```bash
   oc project ${PROJECT_MQ}
   oc apply -k ./kustomize/environment/mq -n ${PROJECT_MQ}
   ```

   > **REFERENCE MATERIAL:** Create a TLS-secured queue manager via [Example: Configuring TLS](https://www.ibm.com/docs/en/ibm-mq/9.2?topic=manager-example-configuring-tls)


#### Deploy Store Simulator application

1. Update the `store-simulator` ConfigMap YAML to point to the specific MQ queue manager's Route:
   ```bash
   export MQ_ROUTE_HOST=$(oc get route store-simulator-mq-ibm-mq-qm -o jsonpath="{.spec.host}" -n ${PROJECT_MQ})
   cat ./kustomize/apps/store-simulator/base/configmap.yaml | envsubst | \
          tee ./kustomize/apps/store-simulator/base/configmap.yaml >/dev/null
   ```

1. The Kafka Connect instance acts as an MQ client and requires the necessary truststore information for secure connecitivity. Copy the truststore secret that was generated by the Store Simulator component deployment to the local Confluent project for re-use by the Connector:
   ```bash
   oc get secret -n ${PROJECT_MQ} -o json store-simulator-mq-truststore | \
      jq -r ".metadata.namespace=\"${PROJECT_STORE_SIMULATOR}\"" | \
      oc apply -n ${PROJECT_STORE_SIMULATOR} -f -
   ```
   **NOTE:** This step is only required if you are running MQ in a different project than the Store Simulator application.

1. Apply Kustomize YAMLs:
   ```bash
   oc project ${PROJECT_STORE_SIMULATOR}
   oc apply -k ./kustomize/apps/store-simulator -n ${PROJECT_STORE_SIMULATOR}
   ```

1. Send messages to MQ via the store simulator application:
   1. The store simulator user interface is exposed as a Route on OpenShift:
      ```bash
      oc get route store-simulator -o jsonpath="{.spec.host}" -n ${PROJECT_STORE_SIMULATOR}
      ```
   1. Access this Route via HTTP in your browser.
   1. Go to the **SIMULATOR** tab.
   1. Select the _IBMMQ_ radio button and use the slider to select the number of messages to send.
   1. Click the **Simulate** button and wait for the _Messages Sent_ window to be populated.

1. Validate messages received in MQ Web Console:
   1. The MQ Web Console is exposed as a Route on OpenShift:
      ```bash
      oc get route store-simulator-mq-ibm-mq-web -o jsonpath="{.spec.host}" -n ${PROJECT_MQ}
      ```
   1. Go to this route via HTTPS in your browser and login.
   1. If you need to determine your _Default authentication_ admin password, it can be retrieved via the following command:
      ```base
      oc get secret -n {CP4I installation project} ibm-iam-bindinfo-platform-auth-idp-credentials -o json | jq -r .data.admin_password | base64 -d -
      ```
   1. Click the **QM1** tile.
   1. Click the **DEV.QUEUE.1** queue.
   1. Verify that the queue depth is equal to the number of messages sent from the store application.


#### Create custom Kafka Connect container images

1. Apply the Kafka Connect components from the Kustomize YAMLs:
   ```bash
   oc project ${PROJECT_CONFLUENT_PLATFORM}
   oc apply -k ./kustomize/environment/kconnect/ -n ${PROJECT_CONFLUENT_PLATFORM}
   oc logs -f buildconfig/confluent-connect-mq -n ${PROJECT_CONFLUENT_PLATFORM}
   ```
   This creates two ImageStreamTags that are based on the official Confluent Platform container images, which can now be referenced locally in the cluster by the Connect Cluster pods. We then create a BuildConfig to create a custom build that provides a container image with the required Confluent Platform MQ Connector binaries pre-installed, which in turn creates an additional ImageStreamTag that allows us to update the Connect Cluster pods to use the new images.

1. The Kafka Connect instance acts as an MQ client and requires the necessary truststore information for secure connecitivity. Copy the truststore secret that was generated by the Store Simulator component deployment to the local Confluent project for re-use by the Connector:
   ```bash
   oc get secret -n ${PROJECT_MQ} -o json store-simulator-mq-truststore | \
      jq -r ".metadata.namespace=\"${PROJECT_CONFLUENT_PLATFORM}\"" | \
      oc apply -n ${PROJECT_CONFLUENT_PLATFORM} -f -
   ```
   **NOTE:** This step is only required if you are running MQ in a different project than the Confluent Platform.

1. Next, we need to patch the ConfigMap the Connectors pod uses to inject JVM configuration parameters (`jvm.config`) into the Connect runtime. We will do this by patching the PhysicalStatefulCluster that manages the Connect cluster. This is required as we are using a non-IBM JVM inside the Confluent-provided Connect images and the default SSL Cipher Suite Mappings used by default are incompatible. By adding the `-Dcom.ibm.mq.cfg.useIBMCipherMappings=false` JVM configuration parameter, we allow the OpenJDK JVM to leverage the Oracle-compatible Cipher Suite Mappings instead.
   ```bash
   oc get psc/connectors -o yaml -n ${PROJECT_CONFLUENT_PLATFORM} | \
      sed 's/   -Dcom.sun.management.jmxremote.ssl=false/   -Dcom.sun.management.jmxremote.ssl=false\n          -Dcom.ibm.mq.cfg.useIBMCipherMappings=false/' | \
      oc replace -n ${PROJECT_CONFLUENT_PLATFORM} -f -
   ```
   **REFERENCE:** If you encounter CipherSuite issues in the Connector logs, reference [TLS CipherSpecs and CipherSuites in IBM MQ classes for JMS](https://www.ibm.com/docs/en/ibm-mq/9.2?topic=jms-tls-cipherspecs-ciphersuites-in-mq-classes) from the IBM MQ documentation.

#### Update Confluent Platform container deployments

This lab assumes that Confluent Platform is deployed via https://github.ibm.com/ben-cornwell/confluent-operator, which utilizes [Confluent Operator Quick Start](https://docs.confluent.io/operator/current/co-quickstart.html) and deploys the Schema Registry, Replicator, Connect, and Control Center components in a single Helm release. This is problematic when following Step 5 of the [Deploy Confluent Connectors](https://docs.confluent.io/operator/current/co-management.html#deploy-confluent-connectors) instructions, as the image registries required cannot be mixed between different components in the same release. Connect requires the internal OpenShift registry for our custom images we just created, while the other components still require the original docker.io registry.

To circumvent this issue, we can manually patch the Kafka Connect `PhysicalStatefulCluster` custom resource for the Confluent Operator to propogate changes down to the pod level and take advantage of the newly built custom Connect images _(as well as the TLS truststore files)_.

```bash
oc patch psc/connectors --type merge --patch "$(cat ./kustomize/environment/kconnect/infra/confluent-connectors-psc-patch.yaml | envsubst)" -n ${PROJECT_CONFLUENT_PLATFORM}
```

However, if Confluent Platform was deployed via the instructions available at [Install Confluent Operator and Confluent Platform](https://docs.confluent.io/operator/current/co-deployment.html) and Connect is available as it's own Helm release (ie `helm get notes connectors`), you can follow Step 5 of the [Deploy Confluent Connectors](https://docs.confluent.io/operator/current/co-management.html#deploy-confluent-connectors) instructions to update the Confluent custom resources via Helm. If this path is taken, you may need to reapply the `useIBMCipherMappings` patch from the previous section.

A `helm upgrade` command may look something like the following:
```bash
helm upgrade --install connectors \
      --values /your/original/values/file/values-file.yaml \
      --namespace ${PROJECT_CONFLUENT_PLATFORM} \
      --set "connect.enabled=true" \
      --set "connect.mountedSecrets[0].secretRef=store-simulator-mq-truststore" \
      --set "global.provider.registry.fqdn=image-registry.openshift-image-registry.svc:5000" \
      --set "connect.image.repository=${PROJECT_CONFLUENT_PLATFORM}/cp-server-connect-operator" \
      --set "connect.image.tag=6.1.1.0-custom-mq" \
      --set "global.initContainer.image.repository=${PROJECT_CONFLUENT_PLATFORM}/cp-init-container-operator" \
      --set "global.initContainer.image.tag=6.1.1.0" \
      ./confluent-operator-1.7.0/helm/confluent-operator
```

1. Log in to Confluent Control Center and navigate to **Home** > **controlcenter.cluster** > **Connect** > **connect-default** > **Add connector** and verify that the **IbmMqSinkConnector** and **IbmMQSourceConnector** are now available as connector options.

1. Optionally, you can run the following `curl` command to verify via the REST API:
   ```bash
   curl --insecure --silent https://$(oc get route connectors-bootstrap -o jsonpath="{.spec.host}" -n ${PROJECT_CONFLUENT_PLATFORM})/connector-plugins | jq .
   ```


#### Configure MQ Connector

1. Create the target Kafka topic in Confluent Platform:
   1. In the Confluent Control Center and navigate to your Connect cluster via **Home** > **controlcenter.cluster** > **Topics** and click **Add a topic**.
   1. Enter _items.openshift_ (or your own custom topic name).
   1. Click **Create with defaults**.

1. Generate a customized MQ connector configuration file based on your local environment:
   ```bash
   export KAFKA_BOOTSTRAP=$(oc get route kafka-bootstrap -o jsonpath="{.spec.host}" -n ${PROJECT_CONFLUENT_PLATFORM}):443

   # Generate the configured Kafka Connect connector configuration file
   cat ./kustomize/environment/kconnect/config/mq-confluent-source-openshift.json | envsubst > ./kustomize/environment/kconnect/config/mq-confluent-source-openshift-configured.json
   ```
   **NOTE:** You will need to manually edit the generated `./kustomize/environment/kconnect/config/mq-confluent-source-openshift-configured.json` file if you used a topic name other than `items.openshift`.

1. Deploy an MQ Connector instance by choosing one of the two paths:
   1. You can deploy a connector instance via the Confluent Control Center UI:
      1. Log in to the Confluent Control Center and navigate to your Connect cluster via **Home** > **controlcenter.cluster** > **Connect** > **connect-default**.
      1. Click **Upload connector config file** and browse to `eda-lab-mq-to-kafka/kustomize/environment/kconnect/config/mq-confluent-source-openshift-configured.json`
      1. Click **Continue**.
      1. Click **Launch**.

   1. You can deploy a connector instance via the Kafka Connect REST API:
      ```bash
      export CONNECTORS_BOOTSTRAP=$(oc get route connectors-bootstrap -o jsonpath="{.spec.host}" -n ${PROJECT_CONFLUENT_PLATFORM})
      curl -i -X PUT -H  "Content-Type:application/json" --insecure \
          https://$CONNECTORS_BOOTSTRAP/connectors/eda-store-source/config \
          -d @kustomize/environment/kconnect/config/mq-confluent-source-openshift-configured.json
      ```
      **REFERENCE:** If you encounter CipherSuite issues in the Connector logs, reference [TLS CipherSpecs and CipherSuites in IBM MQ classes for JMS](https://www.ibm.com/docs/en/ibm-mq/9.2?topic=jms-tls-cipherspecs-ciphersuites-in-mq-classes) from the IBM MQ documentation.


#### Verify end-to-end connectivity

1. Validate records received in Kafka topic in Confluent Platform:
   1. Log in to the Confluent Control Center and navigate to your Connect cluster via **Home** > **controlcenter.cluster** > **Topics** > **items.openshift**.
   1. Click **Messages**.
   1. Enter `0` in the _offset_ textbox and hit **Enter**.
   1. You should see all the messages you sent to the MQ queue now reside in Kafka topics.

1. Validate MQ queues have been drained via the MQ Web Console:
   1. The MQ Web Console is exposed as a route on OpenShift:
      ```bash
      oc get route store-simulator-mq-ibm-mq-web -o jsonpath="{.spec.host}" -n ${PROJECT_MQ}
      ```
   1. Go to this route via HTTPS in your browser and login.
   1. If you need to determine your _Default authentication_ admin password, it can be retrieved via the following command:
      ```bash
      oc get secret -n {CP4I installation project} ibm-iam-bindinfo-platform-auth-idp-credentials -o json | jq -r .data.admin_password | base64 -d -
      ```
   1. Click the **QM1** tile.
   1. Click the **DEV.QUEUE.1** queue.
   1. Verify that the queue depth is zero messages.


### Lab complete!

To clean up the resources deployed via the lab scenario:

1. Resources in the `${PROJECT_STORE_SIMULATOR}` can be removed via:
   ```bash
   oc delete -k ./kustomize/apps/store-simulator/ -n ${PROJECT_STORE_SIMULATOR}
   ```
1. Resources in the `${PROJECT_MQ}` can be removed via:
   ```bash
   oc delete -k ./kustomize/environment/mq/ -n ${PROJECT_MQ}
   ```
1. Resources in the `${PROJECT_CONFLUENT_PLATFORM}` project can be removed, but also require a reset of the Connectors Helm release to the original container images settings:
   * `buildconfig/confluent-connect-mq`
   * `imagestream.image.openshift.io/cp-init-container-operator`
   * `imagestream.image.openshift.io/cp-server-connect-operator`
   * `secret/store-simulator-mq-truststore`
