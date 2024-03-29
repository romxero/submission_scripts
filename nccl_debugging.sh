#!/bin/bash
#SBATCH --job-name=CZ_NCCL_DEBUG
#SBATCH --partition=gpu
#SBATCH --time=01:15:00
#SBATCH --gpus-per-task=1
#SBATCH --ntasks=4
#SBATCH --nodes=4
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=2G
#SBATCH --ntasks-per-node=1
#SBATCH --mail-type=ALL
#SBATCH --output=CZ_NCCL_DEBUG_%j.out
#SBATCH --error=CZ_NCCL_DEBUG_%j.err
#SBATCH -C "a6000"

# MAKE SURE TO CHECK THE MODULES TO MAKE SURE NVHPC-SDK WONT CONFLICT WITH CUDA

# modules.. 
ml purge 
ml load openmpi/4.1.6 cuda/12.2.1_535.86.10 nvhpc-sdk/23.11

# env from DS variables
export NCCL_DEBUG=WARN
export PYTHONFAULTHANDLER=1

# NCCL Variables to toggle in order to achieve better performance.
export NCCL_IB_PCI_RELAXED_ORDERING=0
#export NCCL_IB_PCI_RELAXED_ORDERING=1 

export CUDA_DEVICE_ORDER=PCI_BUS_ID
export NCCL_SOCKET_IFNAME=ib0

# 
export NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml
export MPI_HOME=/hpc/apps/openmpi/4.1.6
export CUDA_HOME=/hpc/apps/x86_64/cuda/12.2.1_535.86.10
export NCCL_HOME=/hpc/apps/x86_64/nvhpc-sdk/23.11/Linux_x86_64/23.11/comm_libs/nccl

# the tests to run
export TESTS_ARRAY=( all_reduce_perf broadcast_perf reduce_perf all_gather_perf all_reduce_sum_perf reduce_scatter_perf broadcast_recv_perf reduce_recv_perf all_gather_recv_perf reduce_scatter_recv_perf )

# export NCCL_IB_HCA=mlx5_0:1 #check this out eventually

# export NCCL_IB_MERGE_NICS=0

# openmpi stuff right here 
export OMPI_MCA_btl="^openib"

# grab nccl-tests from github
if ! [ -d nccl-tests ]; then
# make sure to clone the repository
git clone https://github.com/NVIDIA/nccl-tests.git
cd nccl-tests
fi

# make the nccl tests 

#make MPI=1 MPI_HOME=/hpc/apps/openmpi/4.1.6 CUDA_HOME=/hpc/apps/x86_64/cuda/12.2.1_535.86.10 NCCL_HOME=/hpc/apps/x86_64/nvhpc-sdk/23.11/Linux_x86_64/23.11/comm_libs/nccl
# MPI_HOME=/hpc/apps/openmpi/4.1.6 CUDA_HOME=/hpc/apps/x86_64/cuda/12.2.1_535.86.10 NCCL_HOME=/hpc/apps/x86_64/nvhpc-sdk/23.11/Linux_x86_64/23.11/comm_libs/nccl

make MPI=1 

# mpirun -np 16 --map-by ppr:8:node -hostfile hostfile  \
#        -mca coll_hcoll_enable 0 --bind-to numa \
#        -x  \
#        -x  \
#        -x CUDA_DEVICE_ORDER=PCI_BUS_ID \
#        -x NCCL_SOCKET_IFNAME=eth0 \
#        -x NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml \
#        -x NCCL_DEBUG=WARN \
#        /opt/nccl-tests/build/${TEST} -b 8 -e 8G -f 2 -g 1 -c 0


for TEST in ${TESTS_ARRAY[@]}; do
    echo "Running test: ${TEST}"
    srun -np 4 ./build/${TEST} 
done


exit 0 

# srun -n 4 /opt/nccl-tests/build/${TEST} -b 8 -e 8G -f 2 -g 1 -c 0


# now test the relaxed ordering
#export NCCL_IB_PCI_RELAXED_ORDERING=1 


#!/bin/bash
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
# HPCX_HOME=/hpc/mydata/$USER/hpcx-v2.18-gcc-mlnx_ofed-redhat8-cuda12-x86_64
# 
# 
# if ! [ -d ${HPCX_HOME} ]; then
#     pushd $MYDATA 
#     wget https://content.mellanox.com/hpc/hpc-x/v2.18/hpcx-v2.18-gcc-mlnx_ofed-redhat8-cuda12-x86_64.tbz
#     tar axvf hpcx-v2.18-gcc-mlnx_ofed-redhat8-cuda12-x86_64.tbz
#     popd
# fi
# 
# ml purge
# ml load relion/4.0.1-CU80
# 
# source $HPCX_HOME/hpcx-init.sh
# 
# hpcx_load
# export OMPI_MCA_btl="^openib"
# 
# mpirun -np 4 relion_preprocess_mpi
# 
# hpcx_unload
# 
# exit 0

# Node features notes: 
# AvailableFeatures=gpu,gpunode,compute,a100,a100_40,NVLINK,NVSWITCH,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,a100,a100_40,NVLINK,NVSWITCH,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,a100,a100_40,NVLINK,NVSWITCH,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,a100,a100_40,NVLINK,NVSWITCH,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,a6000,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,a6000,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,a6000,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,a6000,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,a6000,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,a6000,amd,amd_7742
# AvailableFeatures=gpu,gpunode,compute,czii,a100,a100_80,NVLINK,NVSWITCH,amd,amd_7773x
# AvailableFeatures=gpu,gpunode,compute,czii,a100,a100_80,NVLINK,NVSWITCH,amd,amd_7773x