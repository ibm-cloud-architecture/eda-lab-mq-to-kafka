FROM confluentinc/cp-server-connect-operator:6.1.1.0

LABEL description="A custom Kafka Connect image built to include IBM MQ connectors, constructed per instructions via https://docs.confluent.io/operator/current/co-management.html#deploy-confluent-connectors."

ARG CONFLUENT_MQ_SOURCE_VERSION=11.0.2
ARG CONFLUENT_MQ_SINK_VERSION=1.3.2
ARG MQ_ALLCLIENT_VERSION=9.2.2.0

USER root

ADD https://repo1.maven.org/maven2/com/ibm/mq/com.ibm.mq.allclient/${MQ_ALLCLIENT_VERSION}/com.ibm.mq.allclient-${MQ_ALLCLIENT_VERSION}.jar /usr/share/java/kafka/

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-ibmmq:${CONFLUENT_MQ_SOURCE_VERSION} && \
    confluent-hub install --no-prompt confluentinc/kafka-connect-ibmmq-sink:${CONFLUENT_MQ_SINK_VERSION} && \
    cp /usr/share/java/kafka/com.ibm.mq.allclient-${MQ_ALLCLIENT_VERSION}.jar /usr/share/confluent-hub-components/confluentinc-kafka-connect-ibmmq/lib && \
    cp /usr/share/java/kafka/com.ibm.mq.allclient-${MQ_ALLCLIENT_VERSION}.jar /usr/share/confluent-hub-components/confluentinc-kafka-connect-ibmmq-sink/lib && \
    chmod -R 755 /usr/share/confluent-hub-components && \
    chown -R 1001:0 /usr/share/confluent-hub-components

USER 1001
