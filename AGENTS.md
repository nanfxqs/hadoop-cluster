# 项目结构

本项目用于搭建和学习 KVM/libvirt 上的三节点 Hadoop 集群。

```text
.
├── 配置过程教学文档.md       # 集群搭建步骤与问题修复记录
├── 集群说明与使用文档.md     # 集群拓扑、配置、日常使用与排障
├── start-cluster.sh          # 启动虚拟机及 HDFS、YARN、历史服务
├── stop-cluster.sh           # 停止 Hadoop 服务，保留虚拟机运行
├── bg-wait-vm.sh             # 等待系统安装完成、弹出光盘并检查 SSH
├── ks-hadoop01.cfg           # 主节点的 Kickstart 自动安装配置
├── vm-progress.log          # 虚拟机安装后处理日志
├── *.tar.gz / *.tgz         # JDK、Hadoop、ZooKeeper、HBase、Phoenix、Kafka 安装包
├── iso/                     # AlmaLinux 原始及定制安装镜像、校验文件与下载日志
├── iso-extract/             # 安装镜像解包内容，用于定制 ISO
└── sch-test/                # 课程实验材料
    ├── test03/              # Hadoop Shell 操作实验
    └── test04/              # MapReduce 编程实验，含 process.md 过程记录
        # 各实验目录包含实验手册及 result/ 报告，result/assets/ 保存截图
```

涉及集群搭建时阅读 `配置过程教学文档.md`；涉及使用、配置或排障时阅读 `集群说明与使用文档.md`。
