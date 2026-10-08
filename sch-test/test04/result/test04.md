# 实验四 MapReduce 编程实践操作步骤

本实验在现有的 Hadoop 集群上完成：`hadoop01`（`h1`，192.168.122.11）负责提交作业，`hadoop02`、`hadoop03` 运行任务。三台机器已安装 JDK 8 和 Hadoop 3.1.3，Hadoop 路径为 `/usr/local/hadoop`。以下除第一块外，命令均在 **hadoop01 的 `hadoop` 用户终端**执行。手册中的 `hadoop101`、`/usr/local/develop/hadoop-3.1.3` 和 Windows `D:\...` 路径不适用于本集群。

## 1. 启动集群并登录主节点

在项目根目录的**宿主机终端**执行：

```bash
./start-cluster.sh
ssh h1
```

后续命令均在刚登录的 `h1` 终端执行。若集群已经运行，可直接 `ssh h1`。
![[assets/Pasted image 20261008103421.png]]
## 2. 运行 Hadoop 自带的 WordCount

先用手册中的三行文本准备输入，再上传 HDFS。MapReduce 的输出目录必须事先不存在；下面仅清理本实验对应的输出目录，便于重复执行。

```bash
mkdir -p ~/mapreduce-lab
cd ~/mapreduce-lab
printf 'Hello world\nThis is a test\nHello again\n' > word.txt
hdfs dfs -mkdir -p /test04/official/input
hdfs dfs -put -f word.txt /test04/official/input/
hdfs dfs -rm -r -f /test04/official/output
yarn jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.1.3.jar \
  wordcount /test04/official/input /test04/official/output
hdfs dfs -cat /test04/official/output/part-r-*
```

这一步对应手册的官网案例。输入和输出都在 HDFS，作业通过 YARN 运行。
![[Pasted image 20261008103935.png]]
![[Pasted image 20261008103914.png]]
## 3. 编写自己的 WordCount

手册的 `WordMapper`、`WordReducer`、`WordApp` 在这里合成一个 Java 源文件，仍分别完成 Map、Reduce 和作业配置。程序接收 HDFS 输入与输出路径；可选的第三个参数 `clean` 用于手册后续的特殊字符处理。这里直接使用集群已有的 JDK 与 Hadoop 类库编译，无需另装 Maven 或 IDEA。

在 `h1` 终端执行下列整块命令，创建源码并打包：

```bash
cd ~/mapreduce-lab
mkdir -p classes
cat > WordCount.java <<'EOF'
import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCount {
    public static class WordMapper extends Mapper<LongWritable, Text, Text, IntWritable> {
        private static final IntWritable ONE = new IntWritable(1);

        @Override
        protected void map(LongWritable key, Text value, Context context)
                throws IOException, InterruptedException {
            String line = value.toString();
            if (context.getConfiguration().getBoolean("word.clean", false)) {
                line = line.toLowerCase().replaceAll("[^a-z0-9]+", " ");
            }
            for (String word : line.trim().split("\\s+")) {
                if (!word.isEmpty()) {
                    context.write(new Text(word), ONE);
                }
            }
        }
    }

    public static class WordReducer extends Reducer<Text, IntWritable, Text, IntWritable> {
        @Override
        protected void reduce(Text word, Iterable<IntWritable> counts, Context context)
                throws IOException, InterruptedException {
            int sum = 0;
            for (IntWritable count : counts) {
                sum += count.get();
            }
            context.write(word, new IntWritable(sum));
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 2 || args.length > 3) {
            System.err.println("用法: WordCount <HDFS输入> <HDFS输出> [clean]");
            System.exit(1);
        }
        Configuration conf = new Configuration();
        conf.setBoolean("word.clean", args.length == 3 && "clean".equals(args[2]));
        Job job = Job.getInstance(conf, "test04-wordcount");
        job.setJarByClass(WordCount.class);
        job.setMapperClass(WordMapper.class);
        job.setReducerClass(WordReducer.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(IntWritable.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
EOF
javac -cp "$(hadoop classpath --glob)" -d classes WordCount.java
jar -cf test04.jar -C classes .
```

运行自己编写的普通 WordCount，并查看结果：

```bash
hdfs dfs -rm -r -f /test04/custom/output
yarn jar test04.jar WordCount /test04/official/input /test04/custom/output
hdfs dfs -cat /test04/custom/output/part-r-*
```

普通模式按空白字符分词，保留大小写。因此示例中 `Hello` 的计数为 2，`world`、`This`、`is`、`a`、`test`、`again` 各为 1。
![[Pasted image 20261008104201.png]]
![[Pasted image 20261008104215.png]]
## 4. 处理文本中的特殊字符

手册要求在 Map 阶段过滤小说中的标点。上面的 Mapper 在 `clean` 模式下将非英文字母和数字替换为空格，同时统一小写，再分词。这样标点连接的单词不会被错误拼成一个词。准备一小段带标点的文本并提交：

```bash
cd ~/mapreduce-lab
printf 'Hello, world!\nHello-world; hello.\n' > punctuation.txt
hdfs dfs -mkdir -p /test04/clean/input
hdfs dfs -put -f punctuation.txt /test04/clean/input/
hdfs dfs -rm -r -f /test04/clean/output
yarn jar test04.jar WordCount /test04/clean/input /test04/clean/output clean
hdfs dfs -cat /test04/clean/output/part-r-*
```

结果应包含 `hello 3` 和 `world 2`。正则式 `[^a-z0-9]+` 适用于手册所用的英文文本；若输入是中文小说，需要相应调整分词规则。
![[Pasted image 20261008104301.png]]
## 5. 编写成绩排序程序

按手册要求，以 **总分、语文、数学、英语** 依次降序排序。`ScoreBean` 作为 Map 输出的键，实现 `WritableComparable` 供 Shuffle 排序；Reducer 把姓名与分数写出。设置一个 Reducer，使结果保存在一个全局有序的文件中。输入文件使用 **Tab 分隔**的四列：姓名、语文、数学、英语。

在 `h1` 终端执行下列整块命令：

```bash
cd ~/mapreduce-lab
cat > ScoreSort.java <<'EOF'
import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class ScoreSort {
    public static class ScoreBean implements WritableComparable<ScoreBean> {
        private int chinese, math, english, total;

        public ScoreBean() {}

        public ScoreBean(int chinese, int math, int english) {
            this.chinese = chinese;
            this.math = math;
            this.english = english;
            this.total = chinese + math + english;
        }

        @Override
        public void write(DataOutput out) throws IOException {
            out.writeInt(chinese);
            out.writeInt(math);
            out.writeInt(english);
            out.writeInt(total);
        }

        @Override
        public void readFields(DataInput in) throws IOException {
            chinese = in.readInt();
            math = in.readInt();
            english = in.readInt();
            total = in.readInt();
        }

        @Override
        public int compareTo(ScoreBean other) {
            int c = Integer.compare(other.total, total);
            if (c != 0) return c;
            c = Integer.compare(other.chinese, chinese);
            if (c != 0) return c;
            c = Integer.compare(other.math, math);
            if (c != 0) return c;
            return Integer.compare(other.english, english);
        }

        @Override
        public String toString() {
            return chinese + "\t" + math + "\t" + english + "\t" + total;
        }
    }

    public static class ScoreMapper extends Mapper<LongWritable, Text, ScoreBean, Text> {
        @Override
        protected void map(LongWritable key, Text value, Context context)
                throws IOException, InterruptedException {
            String[] fields = value.toString().split("\\t");
            if (fields.length != 4) return;
            int chinese = Integer.parseInt(fields[1]);
            int math = Integer.parseInt(fields[2]);
            int english = Integer.parseInt(fields[3]);
            context.write(new ScoreBean(chinese, math, english), new Text(fields[0]));
        }
    }

    public static class ScoreReducer extends Reducer<ScoreBean, Text, Text, Text> {
        @Override
        protected void reduce(ScoreBean score, Iterable<Text> names, Context context)
                throws IOException, InterruptedException {
            for (Text name : names) {
                context.write(name, new Text(score.toString()));
            }
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("用法: ScoreSort <HDFS输入> <HDFS输出>");
            System.exit(1);
        }
        Job job = Job.getInstance();
        job.setJobName("test04-score-sort");
        job.setJarByClass(ScoreSort.class);
        job.setMapperClass(ScoreMapper.class);
        job.setReducerClass(ScoreReducer.class);
        job.setMapOutputKeyClass(ScoreBean.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        job.setNumReduceTasks(1);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
EOF
javac -cp "$(hadoop classpath --glob)" -d classes ScoreSort.java
jar -uf test04.jar -C classes .
```

准备成绩文件并运行。`printf` 中的 `\t` 会生成 Tab，勿改成普通空格：

```bash
printf '张三\t100\t99\t88\n李四\t88\t88\t88\n王五\t90\t98\t99\n赵六\t100\t98\t89\n' > grade.txt
hdfs dfs -mkdir -p /test04/score/input
hdfs dfs -put -f grade.txt /test04/score/input/
hdfs dfs -rm -r -f /test04/score/output
yarn jar test04.jar ScoreSort /test04/score/input /test04/score/output
hdfs dfs -cat /test04/score/output/part-r-*
```

本例中张三、王五、赵六的总分同为 287，再按语文、数学降序排序，预期顺序为张三、赵六、王五、李四。若两行四项分数完全相同，姓名之间不保证顺序。
![[Pasted image 20261008104419.png]]
## 6. 查看作业页面

在宿主机浏览器打开：

- YARN 作业列表：<http://192.168.122.11:8088>
- 已完成作业历史：<http://192.168.122.11:19888>
- HDFS 文件浏览：<http://192.168.122.11:9870>

可从这些页面查看提交的 WordCount 和成绩排序作业及其输出目录。
![[Pasted image 20261008104459.png]]![[Pasted image 20261008104528.png]]![[Pasted image 20261008104542.png]]