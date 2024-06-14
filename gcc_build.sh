#!/bin/bash
# This script will build the gcc compiler from source.
# 
#git clone git://gcc.gnu.org/git/gcc.git
cd gcc 

wget https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
wget https://www.mpfr.org/mpfr-current/mpfr-4.2.1.tar.xz
wget https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
wget https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2

# ty copilot
# extract the tarballs
tar -axf gmp-6.3.0.tar.xz #-C gmp
tar -axf mpfr-4.2.1.tar.xz # -C mpfr
tar -axf mpc-1.3.1.tar.gz #-C mpc
tar -axf isl-0.24.tar.bz2 #-C isl


mv isl-0.24 isl
mv mpc-1.3.1 mpc
mv gmp-6.3.0 gmp
mv mpfr-4.2.1 mpfr


mkdir gcc_build

pushd gcc_build