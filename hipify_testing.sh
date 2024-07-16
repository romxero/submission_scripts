#!/bin/bash

# This script is used to find all the CUDA files in the motioncorr project
MAIN_PROJ_DIR="/home/randall.white/mydata/motioncorr_dev_work"

pushd ${MAIN_PROJ_DIR}

source spack/share/spack/setup-env.sh

spack load hipify-clang@6.1.2
spack load llvm-amdgpu


# spack find -H -p llvm-amdgpu | cut -d ' ' -f 3
LLVM_DIR=$(spack location -i llvm-amdgpu)

hipify-clang --clang-resource-directory

{
#!/bin/bash 



}

<()

find . -name "*.cu" -print |  wc -l

-exec 