#!/bin/bash 
#SBATCH -J "tomotwin_lbann_integration_research"
#SBATCH --time=04:10:00
#SBATCH -c 12
#SBATCH -n 1
#SBATCH --mem-per-cpu=2G
#SBATCH -p cpu
#SBATCH -N 1
#SBATCH --output=tomotwin_lbann_integration_research_%A.%a.out
#SBATCH --error=tomotwin_lbann_integration_research_%A.%a.err
#SBATCH --mail-type=START,END,FAIL
#SBATCH --mail-user=randall.white@czbiohub.org


# intantiate the SLURM_TASKS_PER_NODE and SLURM_CPUS_PER_TASK variables if they are not already set.

#echo ${SLURM_CPUS_PER_TASK}
# the test environment name 
SPACK_ENV_NAME="LBANN_experiment"

# modules 
ml purge

# we got to install our spack environment here 
git clone -c feature.manyFiles=true https://github.com/spack/spack.git

# source the spack environment
source spack/share/spack/setup-env.sh

# lets find the current compiler and dependencies
#spack compiler find /hpc/apps/x86_64/gcc/11.3
# issue with 11.3 of gcc for some reason? 



# just find about everything we need
spack external find

# install the environment
spack install lbann 

exit 0 


