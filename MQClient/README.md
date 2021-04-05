# MQClient sample

This folder includes a simple JMSPutGet program to test MQ deployment. It is based on [this sample](https://raw.githubusercontent.com/ibm-messaging/mq-dev-samples/master/gettingStarted/jms/com/ibm/mq/samples/jms/JmsPutGet.java), but modified to use environment variables and to be able to be dockerized


## To use this sample on local MQ broker

Set your environment variable in a `.env` file. You need the following from the MQ broker information:

```
export MQ_HOST=localhost
export MQ_PORT=1414
export MQ_CHANNEL=DEV.APP.SVRCONN
export MQ_QUEUE=DEV.QUEUE.1
export MQ_QMGR=QM1
export MQ_APP_PASSWORD=<match the configuration of the docker compose>
export MQ_APP_USER=app
```

Under the MQClient compile with:

```shell
javac -cp com.ibm.mq.allclient-9.2.1.0.jar:javax.jms-api-2.0.1.jar com/ibm/mq/samples/jms/JmsPutGet.java
```

Start MQ broker from the docker compose file in parent folder.

Run it
```
source .env
java -cp com.ibm.mq.allclient-9.2.1.0.jar:javax.jms-api-2.0.1.jar:. com.ibm.mq.samples.jms.JmsPutGet
```

You should get a trace like

```
Sent message:

  JMSMessage class: jms_text
  JMSType:          null
  JMSDeliveryMode:  2
  JMSDeliveryDelay: 0
  JMSDeliveryTime:  1617389037787
  JMSExpiration:    0
  JMSPriority:      4
  JMSMessageID:     ID:414d5120514d31202020202020202020b5656760012b0040
  JMSTimestamp:     1617389037787
  JMSCorrelationID: null
  JMSDestination:   queue:///DEV.QUEUE.1
  JMSReplyTo:       null
  JMSRedelivered:   false
    JMSXAppID: JmsPutGet (JMS)             
    JMSXDeliveryCount: 0
    JMSXUserID: app         
    JMS_IBM_PutApplType: 28
    JMS_IBM_PutDate: 20210402
    JMS_IBM_PutTime: 18435783
Your lucky number today is 770

Received message:
Your lucky number today is 770
SUCCESS
```