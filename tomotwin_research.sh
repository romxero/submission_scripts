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


#WORK NOTES
# currently conda does not work

# intantiate the SLURM_TASKS_PER_NODE and SLURM_CPUS_PER_TASK variables if they are not already set.

#echo ${SLURM_CPUS_PER_TASK}
# the test environment name
SPACK_ENV_NAME="LBANN_experiment"

# modules
ml purge
ml mamba

# we got to install our spack environment here
git clone -c feature.manyFiles=true https://github.com/spack/spack.git

# source the spack environment
source spack/share/spack/setup-env.sh

# lets find the current compiler and dependencies
#spack compiler find /hpc/apps/x86_64/gcc/11.3
# issue with 11.3 of gcc for some reason?

# PLZ TEST GETTING MAMBA/PYHTHON DEPS HERE:
# spack external find /hpc/apps/mamba/23.1.0-3/

# install the environment
spack install -j ${SLURM_CPUS_PER_TASK} lbann
spack install -j ${SLURM_CPUS_PER_TASK} anaconda3
spack install -j ${SLURM_CPUS_PER_TASK} python@3.11.7

# after installation lets load the lbann stuff
spack load lbann
spack load anaconda3@2023.09-0

# create the anaconda environment here:
mamba env create --prefix=/hpc/mydata/randall.white/lbann_research/tomotwin_env -f https://raw.githubusercontent.com/MPI-Dortmund/tomotwin-cryoet/main/conda_env_tomotwin.yml
mamba env create --prefix=/hpc/mydata/randall.white/lbann_research/napari_tomotwin_env -f https://raw.githubusercontent.com/MPI-Dortmund/napari-tomotwin/main/conda_env.yml

exit 0
