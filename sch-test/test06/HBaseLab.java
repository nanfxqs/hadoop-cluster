import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.CompareOperator;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.filter.*;
import org.apache.hadoop.hbase.util.Bytes;

public class HBaseLab {
    private static final TableName NAME = TableName.valueOf("test06_api");
    private static final byte[] CF = Bytes.toBytes("C1");
    private static void print(Result result) {
        if (result.isEmpty()) {
            System.out.println("EMPTY");
            return;
        }
        System.out.println("row=" + Bytes.toString(result.getRow())
            + ", NAME=" + Bytes.toString(result.getValue(CF, Bytes.toBytes("NAME")))
            + ", RECORD_DATE=" + Bytes.toString(result.getValue(CF, Bytes.toBytes("RECORD_DATE")))
            + ", NUM_USAGE=" + Bytes.toString(result.getValue(CF, Bytes.toBytes("NUM_USAGE"))));
    }
    private static Put row(String key, String name, String date, String usage) {
        Put put = new Put(Bytes.toBytes(key));
        put.addColumn(CF, Bytes.toBytes("NAME"), Bytes.toBytes(name));
        put.addColumn(CF, Bytes.toBytes("RECORD_DATE"), Bytes.toBytes(date));
        put.addColumn(CF, Bytes.toBytes("NUM_USAGE"), Bytes.toBytes(usage));
        return put;
    }
    public static void main(String[] args) throws Exception {
        Configuration conf = HBaseConfiguration.create();
        try (Connection connection = ConnectionFactory.createConnection(conf);
             Admin admin = connection.getAdmin()) {
            if (args.length == 1 && "drop".equals(args[0])) {
                if (admin.tableExists(NAME)) {
                    if (admin.isTableEnabled(NAME)) admin.disableTable(NAME);
                    admin.deleteTable(NAME);
                }
                System.out.println("tableExists=" + admin.tableExists(NAME));
                return;
            }
            if (!admin.tableExists(NAME)) {
                admin.createTable(TableDescriptorBuilder.newBuilder(NAME)
                    .setColumnFamily(ColumnFamilyDescriptorBuilder.of(CF)).build());
            }
            System.out.println("tableExists=" + admin.tableExists(NAME));
            try (Table table = connection.getTable(NAME)) {
                table.put(row("100001", "张三", "2024-04-25", "25"));
                table.put(row("100002", "李四", "2024-07-01", "30"));
                System.out.println("GET 100001");
                print(table.get(new Get(Bytes.toBytes("100001"))));
                SingleColumnValueFilter lower = new SingleColumnValueFilter(CF,
                    Bytes.toBytes("RECORD_DATE"), CompareOperator.GREATER_OR_EQUAL,
                    new BinaryComparator(Bytes.toBytes("2024-04-01")));
                SingleColumnValueFilter upper = new SingleColumnValueFilter(CF,
                    Bytes.toBytes("RECORD_DATE"), CompareOperator.LESS_OR_EQUAL,
                    new BinaryComparator(Bytes.toBytes("2024-06-30")));
                lower.setFilterIfMissing(true);
                upper.setFilterIfMissing(true);
                Scan scan = new Scan();
                scan.setFilter(new FilterList(FilterList.Operator.MUST_PASS_ALL, lower, upper));
                System.out.println("SCAN 2024-04-01 .. 2024-06-30");
                try (ResultScanner scanner = table.getScanner(scan)) {
                    for (Result result : scanner) print(result);
                }
                table.delete(new Delete(Bytes.toBytes("100001")));
                System.out.println("AFTER DELETE 100001");
                print(table.get(new Get(Bytes.toBytes("100001"))));
            }
        }
    }
}
