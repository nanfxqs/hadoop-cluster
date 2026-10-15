set -e
source /etc/profile.d/java.sh
hdfs dfs -mkdir -p /test05
printf 'HA data survives failover\n' > /tmp/test05.txt
hdfs dfs -put -f /tmp/test05.txt /test05/probe.txt
for kind in nn rm; do
 active=''
 for i in 1 2 3; do
  if [ "$kind" = nn ]; then state=$(hdfs haadmin -getServiceState nn$i 2>/dev/null); else state=$(yarn rmadmin -getServiceState rm$i 2>/dev/null); fi
  echo "BEFORE $kind$i $state"
  [ "$state" != active ] || active=$i
 done
 [ -n "$active" ]
 if [ "$kind" = nn ]; then command='hdfs --daemon'; service=namenode; else command='yarn --daemon'; service=resourcemanager; fi
 t=$(date +%s)
 echo "STOP hadoop0$active $service"
 ssh hadoop0$active "source /etc/profile.d/java.sh; $command stop $service"
 for attempt in $(seq 1 30); do
  found=''
  for i in 1 2 3; do
   [ "$i" != "$active" ] || continue
   if [ "$kind" = nn ]; then state=$(hdfs haadmin -getServiceState nn$i 2>/dev/null); else state=$(yarn rmadmin -getServiceState rm$i 2>/dev/null); fi
   if [ "$state" = active ]; then found=$i; break; fi
  done
  [ -z "$found" ] || break
  sleep 1
 done
 echo "AFTER $kind$found active; elapsed=$(( $(date +%s) - t )) seconds (including stop/query)"
 [ -n "$found" ]
 hdfs dfs -cat /test05/probe.txt
 ssh hadoop0$active "source /etc/profile.d/java.sh; $command start $service"
done
