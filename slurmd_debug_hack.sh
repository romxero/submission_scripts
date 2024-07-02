#!/bin/bash
# This script is used to run slurmd in debug mode and place the output in /tmp/ for easy reading. 
# Similar to the debug process learned at lanl
#
#


exec > /tmp/slurmd_debug_output.txt 2>&1

set -x

export SLURMCONFIG="/hpc/slurm/etc/slurm.conf"
export LD_LIBRARY_PATH=/hpc/slurm/installed/cuda/current/lib64:/hpc/slurm/installed/current/lib:/lib64:/usr/lib64

/hpc/slurm/installed/current/sbin/slurmd -D

exit 0
