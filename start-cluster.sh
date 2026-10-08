#!/bin/bash
# 一键启动集群：先开三台虚拟机（如未运行），再启动 HDFS + YARN + JHS
V="virsh -c qemu:///system"
for vm in vm-hadoop01 vm-hadoop02 vm-hadoop03; do
  [ "$($V domstate $vm 2>/dev/null)" = "running" ] || $V start $vm
done
echo "等待 SSH 就绪..."
for ip in 11 12 13; do
  for i in $(seq 1 30); do
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3 -o LogLevel=ERROR hadoop@192.168.122.$ip true 2>/dev/null && break
    sleep 5
  done
done
ssh h1 'source /etc/profile.d/java.sh && start-dfs.sh && start-yarn.sh && mapred --daemon start historyserver'
ssh h1 'source /etc/profile.d/java.sh && hdfs dfsadmin -report 2>/dev/null | grep -E "Live datanodes"'
echo "集群已启动: http://192.168.122.11:9870 (HDFS) / :8088 (YARN)"