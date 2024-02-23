#!/bin/bash

#SBATCH --time=1-00:00:00
#SBATCH -c 4
#SBATCH -J "spack_environment_builds"
#SBATCH -p preempted,cpu
#SBATCH -N 1
#SBATCH --mem-per-cpu=2G
#SBATCH --output=spack_environment_builds_%A.%a.out
#SBATCH --error=spack_environment_builds_%A.%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=randall.white@czbiohub.org
#SBATCH -D /home/randall.white/hpc/spack 

# the test environment name 
SPACK_ENV_NAME="MY_TEST_ENVIRONMENT"

# modules 
ml purge
ml load gcc/11.3

# git clone and grab the configuration file 
git clone git@github.com:romxero/spack_cz_tester.git
cp spack_cz_tester/cz_spack.yml .

source spack/share/spack/setup-env.sh

spack compiler find /hpc/apps/x86_64/gcc/11.3

spack env activate -p ${SPACK_ENV_NAME} ./cz_spack.yml

spack install -J ${SLURM_CPUS_PER_TASK}

# END OF SCRIPT
spack env deactivate

exit 0 
