#!/bin/bash
#SBATCH --job-name=relion_build
#SBATCH --partition=cpu,preemptive
#SBATCH --time=1-00:00:00
#SBATCH --gpu=1
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=2G
#SBATCH --mail-type=ALL
#SBATCH --output=relion_build%j.log
#SBATCH --error=relion_build%j.log
#SBATCH -D /hpc/mydata/$USER/relion_build

# time to set up relion environment


# Nice documentation on running relion on hpc:
# https://hpc.nih.gov/apps/RELION/index.html

# OMPI_MCA_btl="self,sm,tcp,ucx"
# export OMPI_MCA_btl="self,sm,tcp,ucx"

#openmpi and relion need to be installed
# our current build directory
MY_BUILD_BASE=$MYDATA/relion_build


mkdir -p $MY_BUILD_BASE
cd $MY_BUILD_BASE


# modules 
ml purge
ml load ctffind/4.1.14 resmap/1.1.4 cuda/12.2.1_535.86.10 motioncor2/1.6.4 openmpi/4.1.6 cmake/3.28.2


#export OMPI_MCA_btl="self,sm,tcp,ucx"

git clone https://github.com/3dem/relion.git
cd relion

# build the specific version
mkdir -p build-cpu


#build the gpu version
###
# MAKE SURE TO ADD CTF OPTION TO BUILD
# https://www3.mrc-lmb.cam.ac.uk/relion/index.php/CTFfind
#


{

rm -rf build-gpu
mkdir -p build-gpu

pushd build-gpu

cmake -DGUI=OFF -DCUDA=ON -DALTCPU=FALSE -DCudaTexture=ON -DCUDA_ARCH=80 \
-DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DMPI_C_COMPILER=mpicc -DMPI_CXX_COMPILER=mpicc -DDoublePrec_CPU=ON -DDoublePrec_GPU=OFF \
-DCMAKE_C_FLAGS="-O3 -g -lm" \
-DCMAKE_CXX_FLAGS="-O3 -g -lm -lstdc++" ../

make -j 8

popd 

}

# build the cpu version
# tbh, I don't think we need this

#exit 0 
# end of relion_build.sh