#!/bin/bash

# This script is used to find all the CUDA files in the motioncorr project
MAIN_PROJ_DIR="/home/randall.white/mydata/motioncorr_dev_work"
MY_CUDA_PATH="/hpc/apps/x86_64/cuda/12.4.0_550.54.14"

pushd ${MAIN_PROJ_DIR}

source spack/share/spack/setup-env.sh

spack load hipify-clang@6.1.2
spack load llvm-amdgpu


# spack find -H -p llvm-amdgpu | cut -d ' ' -f 3
LLVM_DIR=$(spack location -i llvm-amdgpu)

hipify-clang --clang-resource-directory

hipify-clang --clang-resource-directory=$LLVM_DIR/lib/clang/17 GCC2D.cu -o test.cu

hipify-clang --cuda-path=${MY_CUDA_PATH} -I ./MotionCor3/Util -I ./MotionCor3/LibSrc/Include --clang-resource-directory=$LLVM_DIR/lib/clang/17 --cuda-path= GFFT1D.cu -o test.cu

#this is working :
hipify-clang --cuda-path=${MY_CUDA_PATH} -I ./MotionCor3/Util -I ./MotionCor3/LibSrc/Include --clang-resource-directory=$LLVM_DIR/lib/clang/17 --cuda-path= GFFT1D.cu -o test.cu



#<()

#find . -name "*.cu" -print |  wc -l

