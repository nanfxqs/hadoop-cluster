#!/usr/bin/env bash
# 按依赖顺序停服务，虚拟机保持运行。
set -euo pipefail
SSH=(ssh -F /dev/null -o BatchMode=yes -o ConnectTimeout=5 -o LogLevel=ERROR)
"${SSH[@]}" hadoop@192.168.122.11 'source /etc/profile.d/java.sh; if jps | grep -q HMaster; then ~/opt/hbase-2.4.11/bin/stop-hbase.sh; fi'
for i in 1 2 3; do
  "${SSH[@]}" "hadoop@192.168.122.$((10+i))" 'source /etc/profile.d/java.sh; if jps | grep -q Kafka; then ~/opt/kafka_2.12-3.7.0/bin/kafka-server-stop.sh; fi; for n in $(seq 1 30); do jps | grep -q Kafka || exit 0; sleep 1; done; echo "Kafka 未停止" >&2; exit 1'
done
"${SSH[@]}" hadoop@192.168.122.11 'source /etc/profile.d/java.sh; mapred --daemon stop historyserver; stop-yarn.sh; stop-dfs.sh'
for i in 1 2 3; do
  "${SSH[@]}" "hadoop@192.168.122.$((10+i))" 'export JAVA_HOME=/usr/local/jdk1.8.0_212; z=$HOME/opt/apache-zookeeper-3.5.8-bin/bin/zkServer.sh; if [[ -x "$z" ]] && "$z" status >/dev/null 2>&1; then "$z" stop; fi'
done
echo '集群服务已停止（虚拟机仍在运行）'
