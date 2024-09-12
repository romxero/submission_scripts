#!/bin/bash

MY_HEADER="Date|Hour|Cluster|Allocated|Down|PLND Down|Idle|Planned|Reported"


MY_TOTAL_HOURS=384
MY_TEMP_FILE=$(mktemp "/tmp/my_tmp_file.tmp_XXXXXXXX")



for i in $(seq 0 ${MY_TOTAL_HOURS})
do
    MY_SET_DATE=$(date -u +'%FT%H:00:00' -d "$(date +'%F') - $i hours")
    MY_END_DATE=$(date -u +'%FT%H:00:00' -d "$(date +'%F') - $(($i - 1)) hours")

    MY_REPORT=$(sreport cluster utilization -t Hour start=${MY_SET_DATE} end=${MY_END_DATE} -P -n)

    echo "${MY_SET_DATE}|${i}|${MY_REPORT}" 

    #echo "${MY_SET_DATE} ${MY_END_DATE}" 

   sleep .1
done > ${MY_TEMP_FILE}


echo ${MY_HEADER}
cat ${MY_TEMP_FILE} | sort 

exit 0


#sreport cluster utilization -t Hour -P -n