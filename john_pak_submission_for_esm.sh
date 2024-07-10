#!/bin/bash

#SBATCH --mem=96G
#SBATCH --cpus-per-task=4
#SBATCH --gpus=1
#SBATCH --partition=gpu
#SBATCH --array=0-2%3
#SBATCH --time=0-1:0:0
#SBATCH --output=/tmp/%a.esm_array.%A.out

module purge
module load anaconda/2023.03
source activate ESMFold2
export LD_LIBRARY_PATH=/hpc/apps/anaconda/2023.03/envs/ESMFold2/x86_64-conda-linux-gnu/lib:$LD_LIBRARY_PATH

FILE_LIST="sample.list"

# Get the current file name from the list based on the array task ID
FILE_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$FILE_LIST")

# Get the second line of the current file and assign it to the sequence variable
SEQUENCE=$(sed -n '2p' "$FILE_NAME")

# Extract the file name without the extension
FILE_BASENAME=$(basename -- "$FILE_NAME")
OUTPUT_DIR="/hpc/mydata/john.pak/esmfold_predictions/phage_hits/${FILE_BASENAME%.*}"

# Create the output directory
mkdir -p "$OUTPUT_DIR"

# Run your Python script with the current sequence and output directory as arguments
python fold.py --sequence "$SEQUENCE" --output_dir "$OUTPUT_DIR"