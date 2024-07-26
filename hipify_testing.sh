#!/bin/bash


# these variables are likely not needed anymore
MAIN_PROJ_DIR="/home/randall.white/mydata/motioncorr_dev_work"
MY_CUDA_PATH="/hpc/apps/x86_64/cuda/12.4.0_550.54.14"

function gen_env_dirs()
{

    MY_CURR_DIR=$(pwd)

    MY_WORK_DIR="./hip_work" 

    mkdir -p ${MY_WORK_DIR}



}

function enter_directory_and_download_spack_and_install_amd()
{
    pushd ${MY_WORK_DIR}
    
    git clone -c feature.manyFiles=true https://github.com/spack/spack.git

    source spack/share/spack/setup-env.sh
    
    spack install hipify-clang
    
    spack install rocm-cmake    

}


function load_spack_env()
{
    spack load hipify-clang@6.1.2
    spack load llvm-amdgpu

}




function compile_the_project_with_hipify()
{

    hipify-clang --clang-resource-directory

    hipify-clang --clang-resource-directory=$LLVM_DIR/lib/clang/17 GCC2D.cu -o test.cu

    hipify-clang --cuda-path=${MY_CUDA_PATH} -I ./MotionCor3/Util -I ./MotionCor3/LibSrc/Include --clang-resource-directory=$LLVM_DIR/lib/clang/17 --cuda-path= GFFT1D.cu -o test.cu

    #this is working :
    hipify-clang --cuda-path=${MY_CUDA_PATH} -I ./MotionCor3/Util -I ./MotionCor3/LibSrc/Include --clang-resource-directory=$LLVM_DIR/lib/clang/17 --cuda-path= GFFT1D.cu -o test.cu

}


function main()
{
    gen_env_dirs
    enter_directory_and_download_spack
    load_spack_env

    # make sure we get the LLVM directory 
    LLVM_DIR=$(spack location -i llvm-amdgpu)


}




# main execution 
main 
##
##
