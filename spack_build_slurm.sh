#!/bin/bash

#SBATCH --time=4-00:00:00
#SBATCH -c 2 
#SBATCH -J "spack_environment_builds"
#SBATCH -p cpu
#SBATCH -N 1
#SBATCH --mem=4G
#SBATCH --output=spack_environment_builds_%A.%a.out
#SBATCH --error=spack_environment_builds_%A.%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=randall.white@czbiohub.org
#SBATCH -D /home/randall.white/hpc/spack 


# after slurm environment set, lets invoke environments or set modules:

ml purge

git clone git@github.com:romxero/spack_cz_tester.git

cp spack_cz_tester/cz_spack.yml .

ml load gcc/11.3.0

source spack/share/spack/setup-env.sh

spack env activate myenv ./cz_spack.yml

spack install 

# now we direct spack to install some things:

spack env deactivate

exit 0 
