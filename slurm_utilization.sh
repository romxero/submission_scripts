#!/bin/bash

for i in {0..336}
do
    MY_SET_DATE=$(date -u +'%FT%H:00:00' -d "$(date +'%F') - $i hours")

    MY_REPORT=$(sreport cluster utilization -t Hour start=${MY_SET_DATE} end=now -p -n)

    echo "${MY_SET_DATE}|${MY_REPORT}"
    
    sleep 1
done

# echo $MY_SET_DATE

# Set TZ to UTC
export TZ=UTC

sacct --clusters dojo --allusers \
    --parsable2 --noheader --allocations --duplicates \
    --format jobid,jobidraw,cluster,partition,qos,account,group,gid,user,uid,submit,eligible,start,end,elapsed,exitcode,state,nnodes,ncpus,reqcpus,reqmem,reqtres,alloctres,timelimit,nodelist,jobname \
    --starttime 2024-08-24T00:00:00 --endtime now

# Reset TZ
unset TZ

