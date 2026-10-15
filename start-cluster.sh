#!/usr/bin/env bash
# 启动虚拟机和 Hadoop；HA 模式先启动外部 ZooKeeper。
set -euo pipefail
SSH=(ssh -F /dev/null -o BatchMode=yes -o ConnectTimeout=5 -o LogLevel=ERROR)
for i in 1 2 3; do
  vm="vm-hadoop0$i"
  state=$(virsh -c qemu:///system domstate "$vm")
  [[ "$state" == running ]] || virsh -c qemu:///system start "$vm"
done
for i in 1 2 3; do
  ready=false
  for attempt in $(seq 1 30); do
    if "${SSH[@]}" "hadoop@192.168.122.$((10+i))" true 2>/dev/null; then ready=true; break; fi
    sleep 3
  done
  "$ready" || { echo "hadoop0$i SSH 未就绪" >&2; exit 1; }
done
ha=$("${SSH[@]}" hadoop@192.168.122.11 'grep -q "dfs.nameservices" /usr/local/hadoop/etc/hadoop/hdfs-site.xml && echo yes || echo no')
if [[ "$ha" == yes ]]; then
  for i in 1 2 3; do
    "${SSH[@]}" "hadoop@192.168.122.$((10+i))" 'export JAVA_HOME=/usr/local/jdk1.8.0_212; z=$HOME/opt/apache-zookeeper-3.5.8-bin/bin/zkServer.sh; "$z" status >/dev/null 2>&1 || "$z" start'
  done
  for i in 1 2 3; do
    ready=false
    for attempt in $(seq 1 20); do
      if "${SSH[@]}" "hadoop@192.168.122.$((10+i))" 'JAVA_HOME=/usr/local/jdk1.8.0_212 ~/opt/apache-zookeeper-3.5.8-bin/bin/zkServer.sh status' >/dev/null 2>&1; then ready=true; break; fi
      sleep 2
    done
    "$ready" || { echo "ZooKeeper hadoop0$i 未就绪" >&2; exit 1; }
  done
fi
"${SSH[@]}" hadoop@192.168.122.11 'source /etc/profile.d/java.sh; start-dfs.sh; start-yarn.sh; jps | grep -q JobHistoryServer || mapred --daemon start historyserver'
"${SSH[@]}" hadoop@192.168.122.11 'source /etc/profile.d/java.sh; hdfs dfsadmin -report | grep "Live datanodes"'
echo 'Hadoop 已启动；HBase/Kafka 按实验报告单独启动。'
