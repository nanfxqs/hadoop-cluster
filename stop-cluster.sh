#!/bin/bash
# 一键停止集群（虚拟机保持运行；如需彻底关机可再执行 virsh shutdown 或使用快照回滚）
ssh h1 'source /etc/profile.d/java.sh && mapred --daemon stop historyserver; stop-yarn.sh; stop-dfs.sh' 2>/dev/null
echo "集群已停止（虚拟机仍在运行）"