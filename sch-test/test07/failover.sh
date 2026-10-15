set -e
source /etc/profile.d/java.sh
export KAFKA_HOME=$HOME/opt/kafka_2.12-3.7.0
export PATH=$KAFKA_HOME/bin:$PATH
export KAFKA_HEAP_OPTS='-Xms128m -Xmx256m'
BS=hadoop01:9092,hadoop02:9092,hadoop03:9092
echo BEFORE
kafka-topics.sh --bootstrap-server "$BS" --describe --topic test07_ha
echo STOP-broker2
ssh hadoop02 'JAVA_HOME=/usr/local/jdk1.8.0_212 ~/opt/kafka_2.12-3.7.0/bin/kafka-server-stop.sh'
sleep 8
echo AFTER
kafka-topics.sh --bootstrap-server "$BS" --describe --topic test07_ha
printf 'survives broker2 stop\n' | kafka-console-producer.sh --bootstrap-server "$BS" --topic test07_ha --producer-property acks=all
kafka-console-consumer.sh --bootstrap-server "$BS" --topic test07_ha --from-beginning --max-messages 2 --timeout-ms 20000
ssh hadoop02 'JAVA_HOME=/usr/local/jdk1.8.0_212 KAFKA_HEAP_OPTS="-Xms256m -Xmx384m" ~/opt/kafka_2.12-3.7.0/bin/kafka-server-start.sh -daemon ~/opt/kafka_2.12-3.7.0/config/server.properties'
sleep 8
echo RESTORED
kafka-topics.sh --bootstrap-server "$BS" --describe --topic test07_ha
