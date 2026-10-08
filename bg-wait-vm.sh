#!/bin/bash
# 后台任务：等 vm-hadoop01 安装完成 → 弹光盘 → 开机 → 等 SSH
LOG=/home/nanfl/Projects/Learn/hadoop-cluster/vm-progress.log
ts() { date +%H:%M:%S; }
v() { virsh -c qemu:///system "$@" 2>/dev/null; }
vpk() { timeout 90 pkexec virsh -c qemu:///system "$@" 2>/dev/null; }

echo "[$(ts)] 后台任务启动" > $LOG

# 1. 等安装完成自动关机（最多 45 分钟）
for i in $(seq 1 135); do
  st=$(v domstate vm-hadoop01)
  if [ "$st" = "shut off" ]; then echo "[$(ts)] 安装完成，VM 已关机" >> $LOG; break; fi
  sleep 20
done
st=$(v domstate vm-hadoop01)
if [ "$st" != "shut off" ]; then echo "[$(ts)] 超时仍在运行，人工介入" >> $LOG; exit 1; fi

# 2. 弹出光盘
cdrom=$(v dumpxml vm-hadoop01 | grep -oE "target dev='[^']+' bus='ide'" | grep -oE "dev='[^']+'" | cut -d\' -f2 | head -1)
echo "[$(ts)] 光盘设备=${cdrom:-未知}，弹出" >> $LOG
v change-media vm-hadoop01 "$cdrom" --eject >> $LOG 2>&1 || vpk change-media vm-hadoop01 "$cdrom" --eject >> $LOG 2>&1

# 3. 开机
v start vm-hadoop01 >> $LOG 2>&1 || vpk start vm-hadoop01 >> $LOG 2>&1

# 4. 等 SSH 就绪（最多 12 分钟）
for i in $(seq 1 36); do
  if sshpass -p 'Hadoop@123' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o LogLevel=ERROR root@192.168.122.11 'echo SSH_OK' 2>/dev/null; then
    echo "[$(ts)] SSH 就绪！hadoop01 可登录（root / hadoop 用户密码均为 Hadoop@123）" >> $LOG
    exit 0
  fi
  sleep 20
done
echo "[$(ts)] SSH 等待超时，需人工检查网络配置" >> $LOG
