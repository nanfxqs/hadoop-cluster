#!/bin/bash
set -euo pipefail
export JAVA_HOME=/usr/local/jdk1.8.0_212
export KAFKA_HOME=$HOME/opt/kafka_2.12-3.7.0
export PATH=$JAVA_HOME/bin:$KAFKA_HOME/bin:$PATH
export KAFKA_HEAP_OPTS='-Xms128m -Xmx256m'
BS=hadoop01:9092,hadoop02:9092,hadoop03:9092
kafka-broker-api-versions.sh --bootstrap-server "$BS" | head -12
kafka-topics.sh --bootstrap-server "$BS" --create --topic Mytopic_test --partitions 1 --replication-factor 1
kafka-topics.sh --bootstrap-server "$BS" --list
printf 'hello kafka\nproducer consumer test\n' | kafka-console-producer.sh --bootstrap-server "$BS" --topic Mytopic_test
echo '=== consumer: two messages ==='
kafka-console-consumer.sh --bootstrap-server "$BS" --topic Mytopic_test --from-beginning --group mygroup_test --max-messages 2 --timeout-ms 20000 --consumer-property auto.commit.interval.ms=100
kafka-topics.sh --bootstrap-server "$BS" --alter --topic Mytopic_test --partitions 3
kafka-configs.sh --bootstrap-server "$BS" --entity-type topics --entity-name Mytopic_test --alter --add-config flush.messages=100
kafka-topics.sh --bootstrap-server "$BS" --describe --topic Mytopic_test
kafka-topics.sh --bootstrap-server "$BS" --create --topic topic_test2 --partitions 1 --replication-factor 1
printf 'message from second topic\n' | kafka-console-producer.sh --bootstrap-server "$BS" --topic topic_test2
echo '=== multiple topics ==='
kafka-console-consumer.sh --bootstrap-server "$BS" --include 'Mytopic_test|topic_test2' --group grouptest --from-beginning --max-messages 3 --timeout-ms 20000 --consumer-property auto.commit.interval.ms=100 --property print.topic=true
kafka-consumer-groups.sh --bootstrap-server "$BS" --list
kafka-consumer-groups.sh --bootstrap-server "$BS" --describe --group mygroup_test
for option in --to-earliest --to-latest; do
 kafka-consumer-groups.sh --bootstrap-server "$BS" --group mygroup_test --reset-offsets --all-topics "$option" --dry-run
 kafka-consumer-groups.sh --bootstrap-server "$BS" --group mygroup_test --reset-offsets --all-topics "$option" --execute
done
kafka-consumer-groups.sh --bootstrap-server "$BS" --group mygroup_test --reset-offsets --topic Mytopic_test:0 --to-offset 1 --execute
kafka-topics.sh --bootstrap-server "$BS" --create --topic test07_ha --partitions 3 --replication-factor 3 --config min.insync.replicas=2
printf 'replicated message\n' | kafka-console-producer.sh --bootstrap-server "$BS" --topic test07_ha --producer-property acks=all
kafka-topics.sh --bootstrap-server "$BS" --describe --topic test07_ha
kafka-topics.sh --bootstrap-server "$BS" --delete --topic topic_test2
kafka-consumer-groups.sh --bootstrap-server "$BS" --delete --group grouptest
# Keep mygroup_test and Mytopic_test for inspection; demonstrate deletion with grouptest.
