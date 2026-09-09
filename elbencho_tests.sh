#!/bin/bash
#
# WAVE Elbencho Tests — single-client parallel filesystem characterization
#
# Usage: $0 <test_dir> [thread_count] [block_size] [size] [direct_io]
# Example: $0 /WAVE/scratch 16 4M 20g true
#
# Run this on the node you want to measure. <test_dir> is the mountpoint (or
# a writable directory on that filesystem) where dataset files are created.
# Reports stay under $PWD so they do not land on the filesystem under test.
#
# Environment overrides (if set, they win over CLI args):
#   _TEST_DIR_LOCATION  _THREAD_COUNT  _BLOCK_SIZE  _SIZE  _DIRECT_IO
#   _TIME_LIMIT (tiny/small IOPS seconds, default 20)
#   _TIME_LIMIT_LARGE (large-file IOPS seconds, default 300)
#   _META_SHARED_FILES (default 10000)
#
# Timed IOPS: 20s for tiny-file random reads (elbencho's usual IOPS window);
# 300s (5 minutes) for large-file random IOPS. Sequential create/write jobs
# run to completion so the IOPS working set is fully persisted first.
#
# Hardening (Glenn Lockwood / elbencho garden notes):
#   --sync              persist after each phase (not just page cache)
#   --blockvaralgo fast --blockvarpct 100
#                       unique incompressible write buffers (defeat dedup/comp)
#   --dirsharing        all workers in one directory (MDS / dentry lock)
#   --strided           IOR-style interleaved shared-file access
#   --files 1           file-per-thread (IOR -F / N-N)
#   --nolive            no curses UI (logs stay clean on long jobs)
#   --resfile           human-readable result next to each CSV
#
# What this covers:
#
#   1) Metadata
#      size 0 tree (dirs x files per thread): create/stat/read/unlink
#      size 0 --dirsharing hotspot (files per thread, one directory)
#
#   2) Small / modest files
#      4k sequential tiny files
#      4k random tiny-file reads (--rand jumps between files; a 4k file has
#        only one offset). iodepth 1 (latency-bound) and 16 (peak in-flight)
#        plus --lat, --timelimit 20
#      1m files in 128k blocks (many modest files; buffered, not --direct)
#
#   3) Large files
#      N-shared file{1..4}, --strided sequential write then read
#      4k random read IOPS on those files, iodepth 1 and 16, --timelimit 300
#      N-N file-per-thread (--files 1 --dirsharing) sequential write then read
#
# --iodepth 1: one IO at a time per thread (POSIX-style, latency-bound)
# --iodepth 16: 16 in-flight IOs per thread (async, peak IOPS)
#
# Not in this script (add later only if needed):
#   multi-node / distributed elbencho (--hosts / --service)
#   large-file random writes (checkpoint-style write IOPS)
#   extra tiny-file size ladders (16k/64k)
#
# https://na01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fwww.glennklockwood.com%2Fgarden%2Felbencho&data=05%7C02%7C%7C4cbb867d2b1a41ffdb1908df0dfdff19%7C84df9e7fe9f640afb435aaaaaaaaaaaa%7C1%7C0%7C639245056706659097%7CUnknown%7CTWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D%7C0%7C%7C%7C&sdata=31HpYRCceavKDyD%2BUMtAfoBuQPiOiPLIG0TbeSl3wRU%3D&reserved=0
#
#set -x

print_usage()
{
    echo "Usage: $0 <test_dir> [thread_count] [block_size] [size] [direct_io]"
    echo "Example: $0 /WAVE/scratch 16 4M 20g true"
    echo "  test_dir     : mountpoint/path of the filesystem to
characterize (required)"
    echo "  thread_count : threads per elbencho job (default: 16)"
    echo "  block_size   : large-file sequential block size (default: 4M)"
    echo "  size         : large-file size (default: 20g)"
    echo "  direct_io    : true|false — pass --direct on data IO jobs
(default: true)"
}

# command line arguments
if [ $# -eq 0 ] && [ -z "${_TEST_DIR_LOCATION}" ]; then
    print_usage
    exit 1
fi

# default values for the command line arguments
# env vars override CLI; CLI overrides the documented defaults
if [ -n "${_TEST_DIR_LOCATION}" ]; then
    _THREAD_COUNT="${_THREAD_COUNT:-${1:-16}}"
    _BLOCK_SIZE="${_BLOCK_SIZE:-${2:-4M}}"
    _SIZE="${_SIZE:-${3:-20g}}"
    _DIRECT_IO="${_DIRECT_IO:-${4:-true}}"
else
    _TEST_DIR_LOCATION="$1"
    _THREAD_COUNT="${_THREAD_COUNT:-${2:-16}}"
    _BLOCK_SIZE="${_BLOCK_SIZE:-${3:-4M}}"
    _SIZE="${_SIZE:-${4:-20g}}"
    _DIRECT_IO="${_DIRECT_IO:-${5:-true}}"
fi

if ! [[ "${_THREAD_COUNT}" =~ ^[0-9]+$ ]] || [ "${_THREAD_COUNT}" -lt 1 ]; then
    echo "thread_count must be a positive integer, got: ${_THREAD_COUNT}"
    print_usage
    exit 1
fi

_TIME_LIMIT="${_TIME_LIMIT:-20}"
_TIME_LIMIT_LARGE="${_TIME_LIMIT_LARGE:-300}"
if ! [[ "${_TIME_LIMIT}" =~ ^[0-9]+$ ]] || [ "${_TIME_LIMIT}" -lt 1 ]; then
    echo "_TIME_LIMIT must be a positive integer (seconds), got: ${_TIME_LIMIT}"
    exit 1
fi
if ! [[ "${_TIME_LIMIT_LARGE}" =~ ^[0-9]+$ ]] || [
"${_TIME_LIMIT_LARGE}" -lt 1 ]; then
    echo "_TIME_LIMIT_LARGE must be a positive integer (seconds), got:
${_TIME_LIMIT_LARGE}"
    exit 1
fi

## Global Variables ##

# application name
_APP_NAME="WAVE Elbencho Tests"

# node this client is running on (isolates datasets/reports on a shared FS)
_HOSTNAME="$(hostname -s 2>/dev/null || hostname)"

# main reports directory (local/PWD, not on the filesystem under test)
_MAIN_REPORTS_DIR="${PWD}/elbencho_wave_reports/${_HOSTNAME}"

# log directory for the script
_MY_LOG_DIRECTORY="${_MAIN_REPORTS_DIR}/wave_elbencho_tests_logs"

# make sure that this works in the unix environment
_CLI_APP_NAME=$(echo "${_APP_NAME}" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

# log file
_MY_LOG_FILE="${_MY_LOG_DIRECTORY}/${_CLI_APP_NAME}.log"

# lock file to prevent multiple instances of the script from running
_APP_LOCK_FILE="${_MAIN_REPORTS_DIR}/${_CLI_APP_NAME}.lock"

# urls for the elbencho binary
_URL_X86_64="https://na01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fgithub.com%2Fbreuner%2Felbencho%2Freleases%2Fdownload%2Fv3.1-11%2Felbencho-static-x86_64.tar.gz&data=05%7C02%7C%7C4cbb867d2b1a41ffdb1908df0dfdff19%7C84df9e7fe9f640afb435aaaaaaaaaaaa%7C1%7C0%7C639245056706685904%7CUnknown%7CTWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D%7C0%7C%7C%7C&sdata=K1xv349elMMl9HFcfkgRgEGIPc5PiUxfZ47D2SZIS7g%3D&reserved=0"

_URL_AARCH64="https://na01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fgithub.com%2Fbreuner%2Felbencho%2Freleases%2Fdownload%2Fv3.1-11%2Felbencho-static-aarch64.tar.gz&data=05%7C02%7C%7C4cbb867d2b1a41ffdb1908df0dfdff19%7C84df9e7fe9f640afb435aaaaaaaaaaaa%7C1%7C0%7C639245056706708316%7CUnknown%7CTWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D%7C0%7C%7C%7C&sdata=mrowIJxhWlhW6BH4zh3Yv0kLQXK7yqV%2FVk27xWGQvnM%3D&reserved=0"

# this is the location of the parallel file system where the elbencho
tests will be run
_ELBENCHO_TEST_DIR="${_TEST_DIR_LOCATION}/elbencho_wave_fs_tests/${_HOSTNAME}"

_ARCH_TYPE=$(uname -m)

# --direct on data-path jobs when requested
_DIRECT_FLAG=""
case "${_DIRECT_IO}" in
    true|TRUE|yes|YES|1)
        _DIRECT_FLAG="--direct"
        ;;
    false|FALSE|no|NO|0)
        _DIRECT_FLAG=""
        ;;
    *)
        echo "direct_io must be true or false, got: ${_DIRECT_IO}"
        print_usage
        exit 1
        ;;
esac

# empty files per thread in the --dirsharing metadata hotspot
_META_SHARED_FILES="${_META_SHARED_FILES:-10000}"
if ! [[ "${_META_SHARED_FILES}" =~ ^[0-9]+$ ]] || [
"${_META_SHARED_FILES}" -lt 1 ]; then
    echo "_META_SHARED_FILES must be a positive integer, got:
${_META_SHARED_FILES}"
    exit 1
fi

# --sync after each phase (Lockwood: measure persistent media, not page cache)
_SYNC_FLAG="--sync"

# write-path hardening: unique fill + persist + no live UI
_WRITE_HARDEN="--blockvaralgo fast --blockvarpct 100 --sync --nolive"
_RUN_EXTRAS="--nolive"

_ELBENCHO_BIN=""
_TESTS_FAILED=0


## Functions ##

# function to remove lock
remove_lock()
{
    rm -f "${_APP_LOCK_FILE}"
}

# function exit 1 and report issue to system logger
lock_inplace()
{
    logger -p daemon.err -t "${_APP_NAME}" -s "There is another
${_APP_NAME} instance running, exiting"
    exit 1
}

download_file()
{
    local url="$1"
    local dest="$2"

    if command -v wget >/dev/null 2>&1; then
        wget -O "${dest}" "${url}"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "${dest}" "${url}"
    else
        logger -p daemon.err -t "${_APP_NAME}" -s "Neither wget nor
curl is available on ${_HOSTNAME}"
        return 1
    fi
}

install_elbencho()
{
    local url="$1"
    local arch_label="$2"

    if [ -x "${_MAIN_REPORTS_DIR}/elbencho" ]; then
        _ELBENCHO_BIN="${_MAIN_REPORTS_DIR}/elbencho"
        return 0
    fi

    if command -v elbencho >/dev/null 2>&1; then
        _ELBENCHO_BIN="$(command -v elbencho)"
        return 0
    fi

    download_file "${url}" "${_MAIN_REPORTS_DIR}/elbencho.tar.gz"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to download
the elbencho binary for the ${arch_label} architecture"
        return 1
    fi

    tar -xzf "${_MAIN_REPORTS_DIR}/elbencho.tar.gz" -C "${_MAIN_REPORTS_DIR}"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to extract
the elbencho binary for the ${arch_label} architecture"
        return 1
    fi

    rm -f "${_MAIN_REPORTS_DIR}/elbencho.tar.gz"

    if [ ! -x "${_MAIN_REPORTS_DIR}/elbencho" ]; then
        chmod +x "${_MAIN_REPORTS_DIR}/elbencho" 2>/dev/null
    fi

    if [ ! -x "${_MAIN_REPORTS_DIR}/elbencho" ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "elbencho binary
missing after extract for ${arch_label}"
        return 1
    fi

    _ELBENCHO_BIN="${_MAIN_REPORTS_DIR}/elbencho"
    return 0
}

run_elbencho()
{
    "${_ELBENCHO_BIN}" "$@"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "elbencho failed: $*"
        _TESTS_FAILED=1
        return 1
    fi
    return 0
}

# create the main reports directory
if [[ ! -d "${_MAIN_REPORTS_DIR}" ]]; then
    mkdir -p "${_MAIN_REPORTS_DIR}"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to create
the main reports directory"
        exit 1
    fi
fi

# create the log directory
if [[ ! -d "${_MY_LOG_DIRECTORY}" ]]; then
    mkdir -p "${_MY_LOG_DIRECTORY}"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to create
the log directory"
        exit 1
    fi
fi

# ensure that the log file is created
touch "${_MY_LOG_FILE}"
if [ $? -ne 0 ]; then
    logger -p daemon.err -t "${_APP_NAME}" -s "Failed to create the log file"
    exit 1
fi

# filesystem under test must exist and be writable on this node
if [[ -z "${_TEST_DIR_LOCATION}" || "${_TEST_DIR_LOCATION}" == "NULL" ]]; then
    logger -p daemon.err -t "${_APP_NAME}" -s "Filesystem path
(test_dir) is required"
    print_usage
    exit 1
fi

if [[ ! -d "${_TEST_DIR_LOCATION}" ]]; then
    logger -p daemon.err -t "${_APP_NAME}" -s "Test directory does not
exist on ${_HOSTNAME}: ${_TEST_DIR_LOCATION}"
    exit 1
fi

if [[ ! -w "${_TEST_DIR_LOCATION}" ]]; then
    logger -p daemon.err -t "${_APP_NAME}" -s "Test directory is not
writable on ${_HOSTNAME}: ${_TEST_DIR_LOCATION}"
    exit 1
fi


function main() {
# Main function to run the elbencho tests

logger -p daemon.info -t "${_APP_NAME}" -s "Host=${_HOSTNAME}
fs=${_TEST_DIR_LOCATION} threads=${_THREAD_COUNT} block=${_BLOCK_SIZE}
size=${_SIZE} direct_io=${_DIRECT_IO}"
echo "Host: ${_HOSTNAME}"
echo "Filesystem under test: ${_TEST_DIR_LOCATION}"
echo "Dataset directory: ${_ELBENCHO_TEST_DIR}"
echo "Reports directory: ${_MAIN_REPORTS_DIR}"
echo "threads=${_THREAD_COUNT} block=${_BLOCK_SIZE} size=${_SIZE}
direct_io=${_DIRECT_IO} timelimit=${_TIME_LIMIT}s
large_timelimit=${_TIME_LIMIT_LARGE}s
meta_shared_files=${_META_SHARED_FILES}"

case "${_ARCH_TYPE}" in
    x86_64)
        install_elbencho "${_URL_X86_64}" "x86_64" || exit 1
        ;;
    aarch64|arm64)
        install_elbencho "${_URL_AARCH64}" "aarch64" || exit 1
        ;;
    *)
        logger -p daemon.err -t "${_APP_NAME}" -s "Unsupported
architecture: ${_ARCH_TYPE}"
        exit 1
        ;;
esac

# dataset directory on the filesystem under test
if [[ ! -d "${_ELBENCHO_TEST_DIR}" ]]; then
    mkdir -p "${_ELBENCHO_TEST_DIR}"
    if [ $? -ne 0 ]; then
        logger -p daemon.err -t "${_APP_NAME}" -s "Failed to create
the elbencho test directory"
        exit 1
    fi
fi

# create the random test configuration files


## Start tests
logger -p daemon.info -t "${_APP_NAME}" -s "Running the elbencho tests"

#echo "--------------------------------"
#echo "Running the elbencho tests"
#echo "--------------------------------"
#
#
#
## Multi directory and multi file testing
#
#
#echo "Small file parameters: -w -d -t 2 -n 3 -N 4 -s 1m -b 1m
"${_ELBENCHO_TEST_DIR}""
#echo "Running the elbencho tests"
#./elbencho -w -d -t 2 -n 3 -N 4 -s 1m -b 1m "${_ELBENCHO_TEST_DIR}"
#echo "Elbencho tests completed"
#echo "--------------------------------"
#
#
#
## this makes small files in 128k blocks
#./elbencho --mkdirs --write --dirs 128 --files 128 --threads 16
--size 1m --block 128k "${_ELBENCHO_TEST_DIR}"
#
#
## read the files
#./elbencho --mkdirs --write --dirs 128 --files 128 --threads 16
--size 1m --block 128k "${_ELBENCHO_TEST_DIR}"
#
#
#--csvfile
#
#./elbencho --delfiles --deldirs --mkdirs --write --dirs 128 --files
128 --threads 16 --size 1m --block 128k "${_ELBENCHO_TEST_DIR}"


# 1) Metadata: tree (many dirs) then Lockwood --dirsharing hotspot
echo "Metadata: size 0 tree (dirs x files per thread)"

mkdir -p "${_ELBENCHO_TEST_DIR}/tiny_empty"

run_elbencho --mkdirs --write --stat --read --delfiles --deldirs \
  --dirs 128 --files 128 --threads "${_THREAD_COUNT}" --size 0 \
  ${_SYNC_FLAG} ${_RUN_EXTRAS} \
  --csvfile "${_MAIN_REPORTS_DIR}/tiny_empty.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/tiny_empty.txt" \
  "${_ELBENCHO_TEST_DIR}/tiny_empty"

echo "Metadata: size 0 dirsharing hotspot (${_META_SHARED_FILES}
files/thread, one directory)"

mkdir -p "${_ELBENCHO_TEST_DIR}/tiny_empty_shared"

run_elbencho --mkdirs --write --stat --read --delfiles --deldirs \
  --dirsharing --files "${_META_SHARED_FILES}" --threads
"${_THREAD_COUNT}" --size 0 \
  ${_SYNC_FLAG} ${_RUN_EXTRAS} \
  --csvfile "${_MAIN_REPORTS_DIR}/tiny_empty_shared.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/tiny_empty_shared.txt" \
  "${_ELBENCHO_TEST_DIR}/tiny_empty_shared"

echo "Tiny files: size 4k block 4k"

mkdir -p "${_ELBENCHO_TEST_DIR}/tiny_4k"

run_elbencho --mkdirs --write --stat --read --delfiles --deldirs \
  --dirs 128 --files 128 --threads "${_THREAD_COUNT}" --size 4k --block 4k \
  ${_DIRECT_FLAG} ${_WRITE_HARDEN} \
  --csvfile "${_MAIN_REPORTS_DIR}/tiny_4k.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/tiny_4k.txt" \
  "${_ELBENCHO_TEST_DIR}/tiny_4k"


# Random tiny files: --rand jumps between files (a 4k file has only one offset)
echo "Tiny files: size 4k block 4k random-read working set (write)"

mkdir -p "${_ELBENCHO_TEST_DIR}/tiny_4k_rand"

run_elbencho --mkdirs --write \
  --dirs 128 --files 128 --threads "${_THREAD_COUNT}" --size 4k --block 4k \
  ${_DIRECT_FLAG} ${_WRITE_HARDEN} \
  --csvfile "${_MAIN_REPORTS_DIR}/tiny_4k_rand_write.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/tiny_4k_rand_write.txt" \
  "${_ELBENCHO_TEST_DIR}/tiny_4k_rand"

echo "Tiny files: size 4k random read (iodepth 1, ${_TIME_LIMIT}s)"

run_elbencho --read --rand --lat --timelimit "${_TIME_LIMIT}" --iodepth 1 \
  --dirs 128 --files 128 --threads "${_THREAD_COUNT}" --size 4k --block 4k \
  ${_DIRECT_FLAG} ${_RUN_EXTRAS} \
  --csvfile "${_MAIN_REPORTS_DIR}/tiny_4k_rand_read_iodepth1.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/tiny_4k_rand_read_iodepth1.txt" \
  "${_ELBENCHO_TEST_DIR}/tiny_4k_rand"

echo "Tiny files: size 4k random read (iodepth 16, ${_TIME_LIMIT}s)"

run_elbencho --read --rand --lat --timelimit "${_TIME_LIMIT}" --iodepth 16 \
  --dirs 128 --files 128 --threads "${_THREAD_COUNT}" --size 4k --block 4k \
  ${_DIRECT_FLAG} ${_RUN_EXTRAS} \
  --csvfile "${_MAIN_REPORTS_DIR}/tiny_4k_rand_read_iodepth16.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/tiny_4k_rand_read_iodepth16.txt" \
  "${_ELBENCHO_TEST_DIR}/tiny_4k_rand"

run_elbencho --delfiles --deldirs \
  --dirs 128 --files 128 --threads "${_THREAD_COUNT}" ${_RUN_EXTRAS} \
  "${_ELBENCHO_TEST_DIR}/tiny_4k_rand"

# 2) Small files: 1m files in 128k blocks
echo "Small files: size 1m block 128k"

mkdir -p "${_ELBENCHO_TEST_DIR}/small_1m"

run_elbencho --mkdirs --write --stat --read --delfiles --deldirs \
  --dirs 128 --files 128 --threads "${_THREAD_COUNT}" --size 1m --block 128k \
  ${_WRITE_HARDEN} \
  --csvfile "${_MAIN_REPORTS_DIR}/small_1m.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/small_1m.txt" \
  "${_ELBENCHO_TEST_DIR}/small_1m"

# 3) Large files: strided N-shared sequential, then 4k random IOPS, then N-N
echo "Large files: size ${_SIZE} block ${_BLOCK_SIZE} (strided shared
sequential write)"

mkdir -p "${_ELBENCHO_TEST_DIR}/large"

run_elbencho --write --strided --threads "${_THREAD_COUNT}" --block
"${_BLOCK_SIZE}" --size "${_SIZE}" \
  ${_DIRECT_FLAG} ${_WRITE_HARDEN} \
  --csvfile "${_MAIN_REPORTS_DIR}/large_seq_write.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/large_seq_write.txt" \
  "${_ELBENCHO_TEST_DIR}/large/file"{1..4}

echo "Large files: size ${_SIZE} block ${_BLOCK_SIZE} (strided shared
sequential read)"

run_elbencho --read --strided --threads "${_THREAD_COUNT}" --block
"${_BLOCK_SIZE}" --size "${_SIZE}" \
  ${_DIRECT_FLAG} ${_RUN_EXTRAS} \
  --csvfile "${_MAIN_REPORTS_DIR}/large_seq_read.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/large_seq_read.txt" \
  "${_ELBENCHO_TEST_DIR}/large/file"{1..4}

echo "Large files: 4k random read IOPS (iodepth 1, latency-bound,
${_TIME_LIMIT_LARGE}s)"

run_elbencho --read --block 4k --threads "${_THREAD_COUNT}" --iodepth
1 --lat --rand \
  --timelimit "${_TIME_LIMIT_LARGE}" ${_DIRECT_FLAG} ${_RUN_EXTRAS} \
  --csvfile "${_MAIN_REPORTS_DIR}/large_4k_rand_iops_iodepth1.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/large_4k_rand_iops_iodepth1.txt" \
  "${_ELBENCHO_TEST_DIR}/large/file"{1..4}

echo "Large files: 4k random read IOPS (iodepth 16, peak in-flight,
${_TIME_LIMIT_LARGE}s)"

run_elbencho --read --block 4k --threads "${_THREAD_COUNT}" --iodepth
16 --lat --rand \
  --timelimit "${_TIME_LIMIT_LARGE}" ${_DIRECT_FLAG} ${_RUN_EXTRAS} \
  --csvfile "${_MAIN_REPORTS_DIR}/large_4k_rand_iops_iodepth16.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/large_4k_rand_iops_iodepth16.txt" \
  "${_ELBENCHO_TEST_DIR}/large/file"{1..4}

echo "Large files: file-per-thread N-N sequential write (dirsharing)"

mkdir -p "${_ELBENCHO_TEST_DIR}/large_nn"

run_elbencho --mkdirs --write --files 1 --dirsharing \
  --threads "${_THREAD_COUNT}" --block "${_BLOCK_SIZE}" --size "${_SIZE}" \
  ${_DIRECT_FLAG} ${_WRITE_HARDEN} \
  --csvfile "${_MAIN_REPORTS_DIR}/large_nn_seq_write.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/large_nn_seq_write.txt" \
  "${_ELBENCHO_TEST_DIR}/large_nn"

echo "Large files: file-per-thread N-N sequential read (dirsharing)"

run_elbencho --read --files 1 --dirsharing \
  --threads "${_THREAD_COUNT}" --block "${_BLOCK_SIZE}" --size "${_SIZE}" \
  ${_DIRECT_FLAG} ${_RUN_EXTRAS} \
  --csvfile "${_MAIN_REPORTS_DIR}/large_nn_seq_read.csv" \
  --resfile "${_MAIN_REPORTS_DIR}/large_nn_seq_read.txt" \
  "${_ELBENCHO_TEST_DIR}/large_nn"

run_elbencho --delfiles --deldirs --files 1 --dirsharing \
  --threads "${_THREAD_COUNT}" ${_RUN_EXTRAS} \
  "${_ELBENCHO_TEST_DIR}/large_nn"

# delete the test directory if it exists
rm -rf "${_ELBENCHO_TEST_DIR}"

# end tests
logger -p daemon.info -t "${_APP_NAME}" -s "Done running the elbencho tests"
echo "--------------------------------"
echo "Done running the elbencho tests"
echo "--------------------------------"

if [ "${_TESTS_FAILED}" -ne 0 ]; then
    logger -p daemon.err -t "${_APP_NAME}" -s "One or more elbencho
tests failed on ${_HOSTNAME}"
    return 1
fi

return 0

}


# ------------------------------------------------------------------------------------------------
# APP START HERE ##
# ------------------------------------------------------------------------------------------------

if ! command -v flock >/dev/null 2>&1; then
    logger -p daemon.err -t "${_APP_NAME}" -s "flock is not installed
on ${_HOSTNAME}; install util-linux"
    exit 1
fi

(
flock -n -x 610 || lock_inplace # set lock or else exit and log issue
to system logger
trap remove_lock EXIT # remove lock on exit
exec > >(tee -a "${_MY_LOG_FILE}") 2>&1
main
_MAIN_RC=$?



# compressing log directory
echo "Compressing the log directory"
echo "--------------------------------"


# get the current date and append it to the log directory name
_CURRENT_DATE=$(date +%Y-%m-%d-%H-%M-%S)

_LOG_ARCHIVE="${_MAIN_REPORTS_DIR}/WAVE_ELBENCHO_TESTS_LOG_${_HOSTNAME}_${_CURRENT_DATE}.tar.zst"
tar -caf "${_LOG_ARCHIVE}" "${_MY_LOG_DIRECTORY}" 2>/dev/null
if [ $? -ne 0 ]; then
    _LOG_ARCHIVE="${_MAIN_REPORTS_DIR}/WAVE_ELBENCHO_TESTS_LOG_${_HOSTNAME}_${_CURRENT_DATE}.tar.gz"
    tar -czf "${_LOG_ARCHIVE}" "${_MY_LOG_DIRECTORY}"
fi

if [ $? -ne 0 ]; then
    logger -p daemon.err -t "${_APP_NAME}" -s "Failed to compress the
log directory"
    exit 1
fi
echo "Log directory compressed"
echo "--------------------------------"
echo "Compressed file: ${_LOG_ARCHIVE}"
echo "Reports (CSV and resfile): ${_MAIN_REPORTS_DIR}"
echo "--------------------------------"

rm -rf "${_MY_LOG_DIRECTORY}"

exit "${_MAIN_RC}"

) 610>>"${_APP_LOCK_FILE}"
_RC=$?


# APP END HERE ##

echo "--------------------------------"
echo "Compressed logs and reports are under: ${_MAIN_REPORTS_DIR}"
if ls -1 "${_MAIN_REPORTS_DIR}"/WAVE_ELBENCHO_TESTS_LOG_"${_HOSTNAME}"_*.tar.*
>/dev/null 2>&1; then
    echo "Latest compressed file:"
    ls -1t "${_MAIN_REPORTS_DIR}"/WAVE_ELBENCHO_TESTS_LOG_"${_HOSTNAME}"_*.tar.*
| head -n 1
fi
echo "--------------------------------"

exit "${_RC}"
