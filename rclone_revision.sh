#!/bin/bash 
#SBATCH -J "czii_rclone_copy"
#SBATCH --time=7-00:10:00
#SBATCH -c 6
#SBATCH -n 4
#SBATCH --mem-per-cpu=2G
#SBATCH -p cpu
#SBATCH -N 1
#SBATCH --output=czii_rclone_copy_%A.%a.out
#SBATCH --error=czii_rclone_copy_%A.%a.err
#SBATCH --mail-type=START,END,FAIL
##SBATCH --mail-user=randall.white@czbiohub.org

SOURCE_STRING="/tmp"
DESTINATION_STRING="test_copy:/dev/tmp"


MY_RCLONE_BUFF_SIZE=60M
MY_RCLONE_BW_LIMIT=60M
MY_RCLONE_TMP="/tmp/$USER/.rclone_temp"
MY_RCLONE_CACHE="/tmp/$USER/.rclone_cache"

# intantiate the SLURM_TASKS_PER_NODE and SLURM_CPUS_PER_TASK variables if they are not already set.
if ! [ -e SLURM_CPUS_PER_TASK ]
then
    SLURM_CPUS_PER_TASK=6
fi 

if ! [ -e SLURM_TASKS_PER_NODE ]
then
    SLURM_TASKS_PER_NODE=4
fi 

### make the temp directory
if ! [ -d ${MY_RCLONE_TMP} ]
then
    mkdir -p ${MY_RCLONE_TMP} 
fi 

### make the cache directory. 
if ! [ -d ${MY_RCLONE_CACHE} ]
then
    mkdir -p ${MY_RCLONE_CACHE} 
fi 

# make sure to take out the --dry-run flag when you are ready to run for real data transfers 

rclone --dry-run copy ${SOURCE_STRING} ${DESTINATION_STRING} \
--transfers=${SLURM_CPUS_PER_TASK} \
--multi-thread-streams=${SLURM_TASKS_PER_NODE} \
--progress \
--use-mmap \
--temp-dir=${MY_RCLONE_TMP} \
--cache-dir=${MY_RCLONE_CACHE} \
--buffer-size=${MY_RCLONE_BUFF_SIZE} \
--bwlimit=${MY_RCLONE_BW_LIMIT} \
--metadata \
--timeout=30M \
--sftp-concurrency=128 \
--sftp-chunk-size=255K \
--sftp-idle-timeout=30M \
--checkers \
--sftp-use-fstat=true

