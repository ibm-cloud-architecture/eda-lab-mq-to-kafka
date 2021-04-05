docker exec -ti  broker  bash -c "/bin/kafka-topics --bootstrap-server localhost:9092 --create  --replication-factor 1 --partitions 1 --topic lab.items"


docker exec -ti  broker  bash -c "/bin/kafka-topics --bootstrap-server localhost:9092 --create  --replication-factor 1 --partitions 1 --topic lab.inventory"