CONFLUENT_NS=confluent-itgtests
#set -x

if [[ -z $(oc get secret confluent-access-secrets 2> /dev/null) ]]
then
    USERNAME=$(oc get secret kafka-apikeys -n ${CONFLUENT_NS} -o jsonpath='{.data.global_sasl_plain_username}' | base64 --decode)
    PASSWORD=$(oc get secret kafka-apikeys -n ${CONFLUENT_NS} -o jsonpath='{.data.global_sasl_plain_password}' | base64 --decode)
    JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required $USERNAME $PASSWORD;"
    echo $JAAS_CONFIG
    oc create secret generic confluent-access-secrets \
    --from-literal=KAFKA_SASL_MECHANISM=PLAIN \
    --from-literal=KAFKA_SECURITY_PROTOCOL=SASL_PLAINTEXT \
    --from-literal=KAFKA_BOOTSTRAP_SERVERS=kafka.${CONFLUENT_NS}.svc.cluster.local:9071 \
    --from-literal=KAFKA_SASL_JAAS_CONFIG=${JAAS_CONFIG}
fi
