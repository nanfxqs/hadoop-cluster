source /etc/profile.d/java.sh
export HBASE_HOME=$HOME/opt/hbase-2.4.11
printf "status 'simple'\nget 'test06_shell', '100001'\nexit\n" > /tmp/test06-check.hbase
echo BEFORE
$HBASE_HOME/bin/hbase shell -n /tmp/test06-check.hbase
echo STOP-hadoop01-master
$HBASE_HOME/bin/hbase-daemon.sh stop master
sleep 8
echo AFTER
$HBASE_HOME/bin/hbase shell -n /tmp/test06-check.hbase
$HBASE_HOME/bin/hbase-daemon.sh start master
