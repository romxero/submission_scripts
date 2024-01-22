#!/bin/sh

#wget https://www.fftw.org/fftw-3.3.10.tar.gz
#tar axvf fftw-3.3.10.tar.gz

export CC=nvc
export CFLAGS='-fopenmp -pthread -mavx -target=multicore'
export F77=nvfortran
export FFLAGS='' 

./configure \
--enable-openmp \
--enable-threads \
--enable-avx-128-fma \
--enable-avx512 \
--enable-avx2 \
--enable-avx \
--prefix=/hpc/mydata/randall.white/code/fftw_gpu_port

make -j4

make install

make clean

#$ apptainer shell --bind /hpc:/hpc --env "PATH=$PATH","LD_LIBRARY_PATH=$LD_LIBRARY_PATH","CPATH=$CPATH","LIBRARY_PATH=$LIBRARY_PATH" --nv containers/nvhpc_23.11-devel-cuda12.3-rockylinux8.sif
