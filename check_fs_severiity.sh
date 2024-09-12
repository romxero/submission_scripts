#!/bin/bash

#set -x #for debugging

#This will scan the file systems for the given directories and print the size of each directory

#declare the variables for processing 
FS_TO_SCAN=("/data" "/exp")
SLACK_WEBHOOK_URL="contextual.ai"
SLEEP_TIME=$((3600 * 2)) # 4 hours
ERROR_LOG_FILE=$PWD/df_to_slack_errors.err


# associative array
declare -A SEVERITY_THRESHOLDS 

# start 

touch ${ERROR_LOG_FILE} # create the file in question and/or adjust the timestamp

# populate the values to show severity 
for i in $(seq 1 100); do
    
    #an associative array to hold the severity level for each threshold
    if [ $i -ge 1 ] && [ $i -le 59 ]; then
        SEVERITY_THRESHOLDS[$i]="LOW"
    fi
    if [ $i -gt 59 ] && [ $i -le 69 ]; then
        SEVERITY_THRESHOLDS[$i]="MEDIUM"
    fi

    if [ $i -gt 69 ] && [ $i -le 79 ]; then
        SEVERITY_THRESHOLDS[$i]="MEDIUM_HIGH"
    fi

    if [ $i -gt 79 ] && [ $i -le 89 ]; then
        SEVERITY_THRESHOLDS[$i]="HIGH"
    fi
    
    if [ $i -gt 89 ] && [ $i -le 100 ]; then
        SEVERITY_THRESHOLDS[$i]="CRITICAL"
    fi

done


#infinite loop to process whats going on with the file system 

while true; do

    for fs in ${FS_TO_SCAN[@]}; do
        PERCENT_USED=$(df ${fs} --output="pcent" | sed -e 1d | sed 's/%//g' | xargs)
#       echo $PERCENT_USED
        SEVERITY_LEVEL=${SEVERITY_THRESHOLDS[$PERCENT_USED]}
#       echo $SEVERITY_LEVEL

        if [ $SEVERITY_LEVEL == "CRITICAL" ]; then
            MSG_STRING=$(echo "CRITICAL: $fs is $PERCENT_USED% full")
            temp_file=$(mktemp /tmp/tempfile.XXXXXX)
            JSON_STRING="{\"text\": \" Disk Space Usage \\n \`\`\`$MSG_STRING\`\`\` \"}"
            curl -s -f  --retry 2 -X POST -H 'Content-type: application/json' --data "$JSON_STRING" ${SLACK_WEBHOOK_URL} &> ${ERROR_LOG_FILE} 

        fi

        if [ $SEVERITY_LEVEL == "HIGH" ]; then
            MSG_STRING=$(echo "HIGH: $fs is $PERCENT_USED% full")
            JSON_STRING="{\"text\": \" Disk Space Usage \\n \`\`\`$MSG_STRING\`\`\` \"}"
            curl -s -f  --retry 2 -X POST -H 'Content-type: application/json' --data "$JSON_STRING" ${SLACK_WEBHOOK_URL} &> ${ERROR_LOG_FILE}

        fi

        if [ $SEVERITY_LEVEL == "MEDIUM_HIGH" ]; then
            MSG_STRING=$(echo "MEDIUM_HIGH: $fs is $PERCENT_USED% full")
            JSON_STRING="{\"text\": \" Disk Space Usage \\n \`\`\`$MSG_STRING\`\`\` \"}"
            curl -s -f  --retry 2 -X POST -H 'Content-type: application/json' --data "$JSON_STRING" ${SLACK_WEBHOOK_URL} &> ${ERROR_LOG_FILE} 

        fi
        
    done
    
    #sleep for 2 hours
    sleep ${SLEEP_TIME}

done



