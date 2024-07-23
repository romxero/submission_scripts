#!/bin/bash

#this will start the sync at 6pm every day
for i in {0..60}
{

    MY_SET_DATE=$(date +'%FT18:30:00' -d "$(date +'%F') + $i days")
    echo "My start date is: ${MY_SET_DATE}"
    sbatch --begin=${MY_SET_DATE} --dependency=singleton transfer.sh

    sleep 1
}
#cancel everything here:
#squeue -u $USER -o %i,%u,%R | grep Dependency | cut -d ',' -f 1 | xargs -I '{}' scancel '{}'