#!/bin/bash
#SBATCH --job-name=CZ_NCCL_DEBUG
#SBATCH --partition=interactive,gpu
#SBATCH --time=00:15:00
#SBATCH --gpus-per-task=1
#SBATCH --ntasks=4
#SBATCH --nodes=4
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=2G
#SBATCH --ntasks-per-node=1
#SBATCH --mail-type=ALL
#SBATCH --output=CZ_NCCL_DEBUG_%j.log
#SBATCH --error=CZ_NCCL_DEBUG_%j.log
#SBATCH --gres=gpu:a6000:1

# modules
ml purge 
ml load openmpi/4.1.6 cuda/12.2.1_535.86.10

# env from DS variables
export NCCL_DEBUG=WARN
export PYTHONFAULTHANDLER=1

# The rest of the NCCL variables to work with:
export NCCL_IB_PCI_RELAXED_ORDERING=0
export LD_LIBRARY_PATH=/usr/local/nccl-rdma-sharp-plugins/lib:$LD_LIBRARY_PATH
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export NCCL_SOCKET_IFNAME=ib0
export NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml

# openmpi stuff right here 
export OMPI_MCA_btl="^openib"


# grab nccl-tests from github
if ! [ -d nccl-tests ]; then
# make sure to clone the repository
git clone https://github.com/NVIDIA/nccl-tests.git
cd nccl-tests
fi

#make the nccl tests 
make MPI=1 MPI_HOME=/path/to/mpi CUDA_HOME=/path/to/cuda NCCL_HOME=/path/to/nccl

# mpirun -np 16 --map-by ppr:8:node -hostfile hostfile  \
#        -mca coll_hcoll_enable 0 --bind-to numa \
#        -x  \
#        -x  \
#        -x CUDA_DEVICE_ORDER=PCI_BUS_ID \
#        -x NCCL_SOCKET_IFNAME=eth0 \
#        -x NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml \
#        -x NCCL_DEBUG=WARN \
#        /opt/nccl-tests/build/${TEST} -b 8 -e 8G -f 2 -g 1 -c 0
# 
#  


srun -np 4 ./build/all_reduce_perf -b 8 -e 128M -f 2 -g 1

# srun -n 4 /opt/nccl-tests/build/${TEST} -b 8 -e 8G -f 2 -g 1 -c 0




```#!/bin/bash
#SBATCH --job-name=relion_test
#SBATCH --partition=cpu
#SBATCH --time=00:05:00
##SBATCH --ntasks=4
#SBATCH --tasks-per-node=1
##SBATCH --gpus-per-task=1
#SBATCH --nodes=4
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=8G
#SBATCH --mail-type=ALL
#SBATCH --output=relion_test_%j.out
#SBATCH --error=relion_test_%j.err

HPCX_HOME=/hpc/mydata/$USER/hpcx-v2.18-gcc-mlnx_ofed-redhat8-cuda12-x86_64


if ! [ -d ${HPCX_HOME} ]; then
    pushd $MYDATA 
    wget https://content.mellanox.com/hpc/hpc-x/v2.18/hpcx-v2.18-gcc-mlnx_ofed-redhat8-cuda12-x86_64.tbz
    tar axvf hpcx-v2.18-gcc-mlnx_ofed-redhat8-cuda12-x86_64.tbz
    popd
fi

ml purge
ml load relion/4.0.1-CU80

source $HPCX_HOME/hpcx-init.sh

hpcx_load
export OMPI_MCA_btl="^openib"

mpirun -np 4 relion_preprocess_mpi

hpcx_unload

exit 0```