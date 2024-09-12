#!/bin/bash


#This will scan the file systems for the given directories and print the size of each directory

FS_TO_SCAN=("/data" "/exp")

#declare the variables for processing 

SLEEP_TIME=3600 # 1 hour


declare -A SEVERITY_THRESHOLDS 

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

#testing this associative arrauy 

while true; do

    for fs in ${FS_TO_SCAN[@]}; do
        PERCENT_USED=$(df ${fs} --output="pcent" | sed -e 1d | sed 's/%//g' | xargs)
        echo $PERCENT_USED
        SEVERITY_LEVEL=${SEVERITY_THRESHOLDS[$PERCENT_USED]}
        echo $SEVERITY_LEVEL
    done


    #sleep for 1 hour
    sleep 10


done

#echo ${SEVERITY_THRESHOLDS[100]}

