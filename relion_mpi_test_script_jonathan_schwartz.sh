#!/bin/bash 

#SBATCH --cpus-per-task=2
#SBATCH -n 2 
#SBATCH -N 1
#SBATCH -p gpu
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --gpus-per-task=1 
#SBATCH --mem-per-cpu=2G
#SBATCH --output=relion_mpi_test_%A.%a.out
#SBATCH --error=relion_mpi_test_%A.%a.err
#SBATCH --constraint="h100"
#SBATCH -D /hpc/projects/group.czii/krios1.processing/relion/23dec21/run004/ribosome-80S

ml purge
ml load relion-turbo/ver5.0-git-CU90

# debug, uncomment below 
#set -x 

srun --mpi=pmix relion_tomo_subtomo_mpi --t Tomograms/job002/tomograms.star \
--p input/full_picks_J85.star --o Extract/job004/ --b 44 --crop -1 --bin 6 \
--float16 --stack2d --theme classic --j 16 --pipeline_control Extract/job004/


#hopefully this will work
exit 0