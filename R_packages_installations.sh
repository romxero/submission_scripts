#!/bin/sh
#SBATCH --partition=cpu
#SBATCH --time=4-00:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=randall.white@czbiohub.org
#SBATCH -J "R_Package_installs"
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 2 
#SBATCH --mem=4G
#SBATCH --output=R_Package_installs_%A.%a.out
#SBATCH --error=R_Package_installs_%A.%a.err
#SBATCH -D /home/randall.white/Documents/code/R

#load modules
module load R/4.3




cat << EOF > install_R_packages.R
#install packages
MY_PACKAGES <- c ("tidyverse", "fastLink","data.table")
chooseCRANmirror(ind=1) #make sure to get the first mirror 
lapply(MY_PACKAGES, install.packages, Ncpus=${SLURM_CPUS_PER_TASK})

EOF 

#launching the command now
R CMD BATCH ./install_R_packages.R