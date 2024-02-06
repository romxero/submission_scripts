#!/bin/bash 
#SBATCH -J "czii_rclone_copy"
#SBATCH --time=7-00:10:00
#SBATCH -c 6
#SBATCH -n 4
#SBATCH -p preview
#SBATCH -N 1
#SBATCH --output=czii_rclone_copy_%A.%a.out
#SBATCH --error=czii_rclone_copy_%A.%a.err
#SBATCH --mail-type=START,END,FAIL
#SBATCH --mail-user=randall.white@czbiohub.org

##
# Determine if windows or linux
# if linux determine if slurm or not. 
# check to see if rclone is in path
# Load modules
# Check to see if rclone is in path
# if not Download and export new path
# run rclone with high efficiency

MY_SBATCH_STACK=$(head -n20 $0 | grep -i "#SBATCH")
MY_RCLONE_BUFF_SIZE=60M
MY_RCLONE_BW_LIMIT=60M

# grab variables from the script here 
#for S in ${MY_SBATCH_STACK[@]}; do
#  grep $S 
#done


# /local/scratch

# E:\






#rclone tarballs to download here:
WINDOWS_RCLONE_ZIP_URL="https://downloads.rclone.org/v1.65.2/rclone-v1.65.2-windows-amd64.zip"
LINUX_RCLONE_ZIP_URL="https://downloads.rclone.org/v1.65.2/rclone-v1.65.2-linux-amd64.zip"


# Workstation nodes: 
CZII_WS1="10.50.120.54"

#we are backing up workstation 2
CZII_WS2="10.50.120.58"
 
### debug stuff right here 
#set -x 

### module stuff 
ml purge 
ml load rclone/1.65.2

### env vars 
LOCAL_PATH_FOR_SERVER_COPY="" 
SERVER_URI_RAW_STRING="smb://10.50.120.65"
SERVER_IP_ADDRESS="10.50.120.65"

### This ione is for the shared scratch
SERVER_REMOTE_PATH_RAW_STRING="SHARED_SCRATCH"

### dirs
MY_RCLONE_TMP="/tmp/$USER/.rclone_temp"
MY_RCLONE_CACHE="/tmp/$USER/.rclone_cache"

## deal with slurm variables 
### check to see if the slurm variable exist. 

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




### need to set up rclone configuration first before deploying this stuff
SOURCE_STRING=""
DESTINATION_STRING=""


### rclone session here 
rclone copy ${SOURCE_STRING} ${DESTINATION_STRING} \
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