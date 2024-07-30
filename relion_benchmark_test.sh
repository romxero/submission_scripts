#!/bin/bash 

# env variables 
MY_CURR_DIR=$(pwd)
MY_WORK_DIR="${MY_CURR_DIR}/relion_benchmark_directory"
BENCHMARK_PAYLOAD="ftp://ftp.mrc-lmb.cam.ac.uk/pub/scheres/relion_benchmark.tar.gz"
MY_HIP_WORK_DIR="./hip_work" 
OMPI_DOWNLOAD_LINK="https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.5.tar.gz"
UCX_DOWNLOAD_LINK="https://github.com/openucx/ucx/releases/download/v1.17.0/ucx-1.17.0.tar.gz"
MY_CORE_COUNT=24 # don't use too much lol
INSTALL_DEST_DIR=${MY_WORK_DIR}/install_dir 


function download_openmpi_and_ucx_then_install()
{
    wget ${OMPI_DOWNLOAD_LINK}
    tar -xvf openmpi-5.0.5.tar.gz
   
   wget ${UCX_DOWNLOAD_LINK}
   tar -xvf v1.17.0.tar.gz
   
   #ucx installation
   pushd ucx-1.17.0/
   mkdir -p build 
   pushd build 

   bash ../contrib/configure-release --prefix=${INSTALL_DEST_DIR} \
    --with-rocm=/opt/rocm \
    --without-cuda -enable-optimizations -disable-logging \
    --disable-debug -disable-assertions \
    --disable-params-check -without-java

    make -j ${MY_CORE_COUNT}
    make install
    #clean it up
    make distclean
    make clean
   popd
   # exit build dir
   popd 
   # exit ucx dir

   #openmpi installation

}

# these variables are likely not needed anymore
#MAIN_PROJ_DIR="/home/randall.white/mydata/motioncorr_dev_work"
#MY_CUDA_PATH="/hpc/apps/x86_64/cuda/12.4.0_550.54.14"


function grab_build_packages()
{
    sudo apt update
    sudo add-apt-repository -y ppa:apptainer/ppa
    sudo apt update
    sudo apt-get install cmake fuse3 libfuse3-dev
    sudo apt install -y apptainer-suid
}

function set_ulimit()
{
    ulimit -n 2038
    ulimit -s unlimited
    ulimit -c unlimited
    ulimit -d unlimited
    ulimit -f unlimited

    #ulimit -l unlimited

}

function grab_relion_deps()
{

    #ctffind
    wget -O ctffind-4.1.14.tar.gz "https://grigoriefflab.umassmed.edu/system/tdf?path=ctffind-4.1.14.tar.gz&file=1&type=node&id=26"

    #resmap
    wget -O ResMap-1.1.4-src.zip "https://downloads.sourceforge.net/project/resmap/src/ResMap-1.1.4-src.zip?ts=gAAAAABmqBK_p1NF6D2AMze6w2Z_Req33IWXrlzAm-4Rk0X8UBXnS4RN0X5oSRfBiyv7CaUIpB2nhF-m82a9CYTVAqS4C35AVA%3D%3D&r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fresmap%2Ffiles%2Fsrc%2FResMap-1.1.4-src.zip%2Fdownload"
}

function gen_env_dirs_and_pushd()
{
    mkdir -p ${MY_WORK_DIR}

    pushd ${MY_WORK_DIR}

}

function grab_relion_repo()
{

    git clone https://github.com/3dem/relion.git relion_ver4
    git clone https://github.com/3dem/relion.git relion_ver5


    # grab and switch to version 4
    pushd relion_ver4
    git fetch --all 
    git switch ver4.0
    popd 

    # grab and switch to version 5
    pushd relion_ver5
    git fetch --all 
    git switch ver5.0
    popd 
    

}



function build_relion_for_amd()
{


for C_ARCH in ${MY_CUDA_ARCH[@]};
do

    {

    rm -rf build-gpu_${C_ARCH}
    mkdir -p build-gpu_${C_ARCH}

    pushd build-gpu_${C_ARCH}

    make clean

    cmake -DGUI=ON -DCUDA=ON -DALTCPU=FALSE -DCudaTexture=ON -DCUDA_ARCH=${C_ARCH} \
    -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DMPI_C_COMPILER=mpicc -DMPI_CXX_COMPILER=mpicc \
    -DDoublePrec_CPU=ON -DDoublePrec_GPU=OFF \
    -DCMAKE_C_FLAGS="-O2 -g -lm -mavx2" \
    -DCMAKE_CXX_FLAGS="-O2 -g -lm -lstdc++ -mavx2" \
    -DPYTHON_EXE_PATH="/usr/bin/python3.9" \
    -DCMAKE_INSTALL_PREFIX="/hpc/apps/relion-turbo/ver5.0-git-CU${C_ARCH}" \
    ..

    make -j 8


    make install

    popd

    }

done



}


function download_benchmark_data_and_scripts()
{

    wget ${BENCHMARK_PAYLOAD}
 
    tar -xvf relion_benchmark.tar.gz

 #   pushd relion_benchmark

    # this is the main script that we will run 
    #./run_benchmark.sh

 
}

function enter_directory_and_download_spack_and_install_amd()
{
    pushd ${MY_WORK_DIR}
    
    git clone -c feature.manyFiles=true https://github.com/spack/spack.git

    source spack/share/spack/setup-env.sh
    
    # find external packages to use with spack first 
    spack external find
    spack external find /usr
    spack external find /opt 
    
    # get the compilers loaded up 
    spack compiler find
    spack compiler rm gcc@12.3.0 

    # time to install some packages 
    spack install -j ${MY_CORE_COUNT} gcc@14.1.0
    spack install hipify-clang
    spack install apptainer@1.3.3
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
    gen_env_dirs_and_pushd
    download_benchmark_data_and_scripts
    enter_directory_and_download_spack
    load_spack_env

    # make sure we get the LLVM directory 
    LLVM_DIR=$(spack location -i llvm-amdgpu)


}




# main execution 
main 
##
##


#!/bin/bash 
#SBATCH --cpus-per-task=2
#SBATCH -n 2
#SBATCH -N 1