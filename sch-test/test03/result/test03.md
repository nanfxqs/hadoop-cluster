# Hadoop 常用 Shell 操作实验

## 实验目标

在已配置的 Hadoop 3.x 集群上，启动并检查集群服务，练习使用 Hadoop Shell 管理 HDFS 文件和目录，并了解通过浏览器访问 HDFS 的配置方式。

## 实验环境与约定

- Linux 虚拟机或云主机；已安装 JDK 8 和 Hadoop 3.x。
- 以下命令默认以集群安装用户（示例为 `hadoop`）登录，并且 Hadoop 命令已加入 `PATH`。如未配置，请先进入 Hadoop 安装目录，或使用 `$HADOOP_HOME/bin/hadoop` 代替 `hadoop`。
- 手册示例安装目录为 `/usr/local/develop/hadoop-3.1.3`，NameNode 主机示例为 `hadoop100`。请按自己的集群配置替换。
- `hadoop fs` 和 `hdfs dfs` 是等价入口；本文统一使用 `hadoop fs`。
- 在具备 HDFS 写权限的账号下操作。下面的删除命令会真实删除 HDFS 中的数据，执行前核对路径。

## 1. 启动并检查集群

在 NameNode 节点以 Hadoop 安装用户启动 HDFS；如果本实验环境也配置了 YARN，再启动 YARN：

```bash
start-dfs.sh
start-yarn.sh
```

在各节点检查 Java 进程：

```bash
jps
```

HDFS 集群应能看到 `NameNode`、`SecondaryNameNode` 和一个或多个 `DataNode`。若启动了 YARN，还应能看到 `ResourceManager`、`NodeManager`。实际进程分布取决于集群节点配置。
![[test03-1790236427300.webp]]
## 2. 查看 Hadoop Shell 帮助

```bash
hadoop fs
hadoop fs -help
hadoop fs -help ls
```

常见子命令包括：`-ls`、`-mkdir`、`-put`、`-copyFromLocal`、`-moveFromLocal`、`-get`、`-copyToLocal`、`-cat`、`-appendToFile`、`-cp`、`-mv`、`-chmod`、`-chown`、`-rm`、`-du` 和 `-setrep`。

## 3. 创建练习目录并准备本地文件

在本地文件系统创建 HDFS 目录：

```bash
hadoop fs -mkdir -p /sanguo
hadoop fs -ls /
```

在当前本地目录创建练习文件：

```bash
printf 'shuguo\n' > shuguo.txt
printf 'weiguo\n' > weiguo.txt
printf 'wuguo\n' > wuguo.txt
printf 'liubei\n' > liubei.txt
```

确认本地文件内容：

```bash
cat shuguo.txt weiguo.txt wuguo.txt liubei.txt
```
![[test03-1790236591012.webp]]
## 4. 上传文件到 HDFS

### 4.1 剪切上传

`-moveFromLocal` 会把本地文件移动到 HDFS；成功后本地源文件不再保留：

```bash
hadoop fs -moveFromLocal ./shuguo.txt /sanguo/
```

### 4.2 复制上传

`-copyFromLocal` 和 `-put` 将本地文件复制到 HDFS。生产环境中常用 `-put`：

```bash
hadoop fs -copyFromLocal ./weiguo.txt /sanguo/
hadoop fs -put ./wuguo.txt /sanguo/
```

### 4.3 追加内容

`-appendToFile` 将本地文件内容追加到已有的 HDFS 文件末尾：

```bash
hadoop fs -appendToFile ./liubei.txt /sanguo/shuguo.txt
```

查看上传结果：

```bash
hadoop fs -ls /sanguo
hadoop fs -cat /sanguo/shuguo.txt
```

`shuguo.txt` 应包含原来的 `shuguo` 和追加的 `liubei` 两行。
![[test03-1790236663168.webp]]
## 5. 从 HDFS 下载文件

`-copyToLocal` 与 `-get` 都会把 HDFS 文件复制到本地：

```bash
hadoop fs -copyToLocal /sanguo/shuguo.txt ./shuguo-copy.txt
hadoop fs -get /sanguo/shuguo.txt ./shuguo-get.txt
```

确认本地文件：

```bash
cat ./shuguo-copy.txt ./shuguo-get.txt
```
![[test03-1790236712354.webp]]
## 6. 常用 HDFS 文件和目录操作

### 6.1 查看、读取和检查

```bash
hadoop fs -ls /sanguo
hadoop fs -cat /sanguo/shuguo.txt
hadoop fs -tail /sanguo/shuguo.txt
hadoop fs -du -h /sanguo
hadoop fs -du -s -h /sanguo
hadoop fs -count /sanguo
```

`-du -s -h` 汇总目录用量；`-du -h` 显示目录下各项用量。HDFS 副本会影响实际占用空间。
![[test03-1790236745189.webp]]
### 6.2 修改权限和属主

```bash
hadoop fs -chmod 666 /sanguo/shuguo.txt
hadoop fs -chown hadoop:hadoop /sanguo/shuguo.txt
```
![[test03-1790236799702.webp]]
将示例属主替换为集群中实际存在的用户和用户组；执行者还需具备相应权限。

### 6.3 复制和移动 HDFS 文件

创建目标目录并复制文件：

```bash
hadoop fs -mkdir -p /jinguo
hadoop fs -cp /sanguo/shuguo.txt /jinguo/
```

将另外两个文件移动到目标目录：

```bash
hadoop fs -mv /sanguo/wuguo.txt /jinguo/
hadoop fs -mv /sanguo/weiguo.txt /jinguo/
```

检查目录和文件：

```bash
hadoop fs -ls /sanguo
hadoop fs -ls /jinguo
hadoop fs -tail /jinguo/shuguo.txt
```
![[test03-1790236880094.webp]]
### 6.4 设置副本数

```bash
hadoop fs -setrep 3 /jinguo/shuguo.txt
```

实际可保存的副本数受可用 DataNode 数量和集群策略限制。设置值不代表集群当前一定已经有相同数量的副本。
![[test03-1790236906503.webp]]
### 6.5 删除练习数据

先删除单个文件：

```bash
hadoop fs -rm /sanguo/shuguo.txt
```

递归删除整个练习目录及其内容：

```bash
hadoop fs -rm -r /sanguo
```

确认目录已删除：

```bash
hadoop fs -ls /
```

如需保留实验结果，请跳过删除命令。也可清理另一个目录：`hadoop fs -rm -r /jinguo`，执行前确认目录内容。
![[test03-1790236950212.webp]]
## 7. 浏览器访问 HDFS（可选）

手册提示，浏览器直接操作 HDFS 时可能因访问身份没有权限而失败。需要配置静态 Web 用户，并重启相关服务。此项会修改集群配置，先备份配置文件并按现有配置合并属性，不要用示例覆盖已有内容。

在每个需要配置的节点上，将以下属性加入 Hadoop 的 `core-site.xml` 的 `<configuration>` 节点中：

```xml
<property>
  <name>hadoop.http.staticuser.user</name>
  <value>hadoop</value>
</property>
```

手册中的示例配置还包含：

```xml
<property>
  <name>fs.defaultFS</name>
  <value>hdfs://hadoop100:9000</value>
</property>
<property>
  <name>hadoop.tmp.dir</name>
  <value>/usr/local/develop/hadoop-3.1.3/data</value>
</property>
```

`fs.defaultFS`、端口和 `hadoop.tmp.dir` 必须与本集群现有配置一致；不要仅为浏览器访问而覆盖集群当前值。将修改后的配置按集群管理方式分发到其他节点，然后重启 HDFS 服务。网页地址与端口取决于集群实际配置，可从 NameNode Web UI 地址确认后再访问。

## 8. 实验完成检查

```bash
hadoop fs -ls /sanguo
hadoop fs -ls /jinguo
hadoop fs -du -h /jinguo
hadoop fs -cat /jinguo/shuguo.txt
```

确认创建、上传、追加、下载、复制、移动、权限修改和副本数设置等操作符合预期；若已执行清理步骤，则以删除后的目录状态为准。
![[test03-1790237018681.webp]]