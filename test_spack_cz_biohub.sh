#!/bin/bash

#SBATCH --time=4-00:00:00
#SBATCH -c 2 
#SBATCH -J "rcs_spack_build_test"
#SBATCH -p cpu
#SBATCH -N 1
#SBATCH --mem=4G
#SBATCH --output=rcs_spack_build_test_%A.%a.out
#SBATCH --error=rcs_spack_build_test_%A.%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=randall.white@czbiohub.org
#SBATCH -D /home/randall.white/hpc/spack 


#after slurm environment set, lets invoke environments or set modules:

source /home/randall.white/hpc/spack/share/spack/setup-env.sh


#now we direct spack to install some things:

spack install gcc