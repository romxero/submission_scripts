#!/bin/bash
set -x

# command line arguments 
if [ $# -eq 0 ]; then
    echo "Usage: $0 <thread_count> <block_size> <size> <direct_io>"
    exit 1
fi



# default values for the command line arguments 
_THREAD_COUNT=${_THREAD_COUNT:-$1} # 16 threads default is 16
_BLOCK_SIZE=${_BLOCK_SIZE:-$2} # 4M default is 4M
_SIZE=${_SIZE:-$3} # 20g
_DIRECT_IO=${_DIRECT_IO:-$4} # true or false default is true



## Global Variables ##

# application name
_APP_NAME="WAVE Elbencho Tests"

# main reports directory
_MAIN_REPORTS_DIR=${PWD}/elbencho_wave_reports # main reports directory

# log directory for the script
_MY_LOG_DIRECTORY="${_MAIN_REPORTS_DIR}/wave_elbencho_tests_logs" # log directory for the script

# make sure that this works in the unix environment
_CLI_APP_NAME=$(echo ${_APP_NAME} | tr '[:upper:]' '[:lower:]' | tr ' ' '_' ) # convert to not have any new lines in the application name

# log file
_MY_LOG_FILE="${_MY_LOG_DIRECTORY}/${_CLI_APP_NAME}.log" # log file for the script

# lock file to prevent multiple instances of the script from running
_APP_LOCK_FILE="${_MAIN_REPORTS_DIR}/${_CLI_APP_NAME}.lock" # lock file to prevent multiple instances of the script from running

# urls for the elbencho binary 
_URL_X86_64=https://github.com/breuner/elbencho/releases/download/v3.1-11/elbencho-static-x86_64.tar.gz

_URL_AARCH64=https://github.com/breuner/elbencho/releases/download/v3.1-11/elbencho-static-aarch64.tar.gz

# this is the location of the parallel file system where the elbencho tests will be ran
_TEST_DIR_LOCATION="NULL" # default is NULL

_ELBENCHO_TEST_DIR="${_TEST_DIR_LOCATION}/elbencho_wave_fs_tests" # this is the location of the elbencho test directory

_ARCH_TYPE=$(uname -m) # architecture type



## Functions ##

#function to remove lock
remove_lock()
{
    rm -f "${_APP_LOCK_FILE}"
}

#function exit 1 and report issue to system logger
lock_inplace()
{
    logger -p daemon.err -t "${_APP_NAME}" -s "There is another ${_APP_NAME} instance running, exiting"
    exit 1
}


# create the main test directory 
if [[ ! -d "${_MAIN_REPORTS_DIR}" ]]; then
    mkdir -p "${_MAIN_REPORTS_DIR}"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to create the main test directory"
        exit 1
    fi
fi

# create the log directory
if [[ ! -d "${_MY_LOG_DIRECTORY}" ]]; then
    mkdir -p "${_MY_LOG_DIRECTORY}"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to create the log directory"
        exit 1
    fi
fi

# ensure that the log file is created
touch "${_MY_LOG_FILE}"
if [ $? -ne 0 ]; then
    logger -p daemon.err -t "${_APP_NAME}" -s "Failed to create the log file"
    exit 1
fi





function main() {
# Main function to run the elbencho tests

# change to the main test directory 
pushd "${_MAIN_REPORTS_DIR}"


if [ "${_ARCH_TYPE}" == "x86_64" ]; then
    wget -O elbencho.tar.gz "${_URL_X86_64}" 
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to download the elbencho binary for the x86_64 architecture"
        exit 1
    fi
    tar -xzf elbencho.tar.gz
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to extract the elbencho binary for the x86_64 architecture"
        exit 1
    fi
    rm -f elbencho.tar.gz
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to remove the elbencho binary for the x86_64 architecture"
        exit 1
    fi
elif [ "${_ARCH_TYPE}" == "aarch64" ]; then
    wget -O elbencho.tar.gz "${_URL_AARCH64}"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to download the elbencho binary for the aarch64 architecture"
        exit 1
    fi
    tar -xzf elbencho.tar.gz
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to extract the elbencho binary for the aarch64 architecture"
        exit 1
    fi
    rm -f elbencho.tar.gz
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to remove the elbencho binary for the aarch64 architecture"
        exit 1
    fi
else
    logger -p daemon.err -t "${_APP_NAME}" -s "Unsupported architecture: ${_ARCH_TYPE}"
    exit 1
fi




# main test directory 
if [[ ! -d "${_ELBENCHO_TEST_DIR}" ]]; then
    mkdir -p "${_ELBENCHO_TEST_DIR}"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to create the elbencho test directory"
        exit 1
    fi
fi

# create the random test configuration files 


## Start tests

logger -p daemon.info -t "${_APP_NAME}" -s "Running the elbencho tests"

echo "--------------------------------"
echo "Running the elbencho tests"
echo "--------------------------------"
echo "Small file parameters: -w -d -t 2 -n 3 -N 4 -s 1m -b 1m "${_ELBENCHO_TEST_DIR}""
echo "Running the elbencho tests"
./elbencho -w -d -t 2 -n 3 -N 4 -s 1m -b 1m "${_ELBENCHO_TEST_DIR}"
echo "Elbencho tests completed"
echo "--------------------------------\n\n\n\n"



# this makes small files in 128k blocks
./elbencho --mkdirs --write --dirs 128 --files 128 --threads 16 --size 1m --block 128k "${_ELBENCHO_TEST_DIR}"

local _LARGE_FILE_PARAMETERS='-w -b 4M -t 16 --direct -s 20g "${_TEST_DIR_LOCATION}/file[1-4]"' # large file parameters


# delete the test directory if it exists
elbencho -F -D -t 2 -n 3 -N 4 ${ELBENCHO_TEST_DIR}


# end tests
logger -p daemon.info -t "${_APP_NAME}" -s "Done running the elbencho tests"
echo "--------------------------------"
echo "Done running the elbencho tests"
echo "--------------------------------"
echo "--------------------------------\n\n\n\n"


popd

return 0

}


# ------------------------------------------------------------------------------------------------
# APP START HERE ##
# ------------------------------------------------------------------------------------------------
(
flock -x 610 || lock_inplace #set lock or else exit and log issue to system logger
trap remove_lock EXIT #remove lock on exit
main
) 610>>${_APP_LOCK_FILE}






exit 0 

