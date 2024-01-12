#SBATCH --array=1-12%1
#SBATCH --time=05:30:00
#SBATCH --nodes=1
#SBATCH --gpus=4
#SBATCH --partition=gpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=80
#SBATCH --job-name=test_downscale_script 
#SBATCH --output=job_outputs/step_01_v2/output_%A_%a.out
#SBATCH --error=job_outputs/step_01_v3/output_%A_%a.err
#SBATCH -D /hpc/projects/group.czii/reza.paraan/UCSF_krios1/reza.paraan_20231115_mito/overnight/2000thickness_Bin4_all

set -ex 
mkdir -p job_outputs/step_01_v2

# Input Pixel Size from Experiment
pxSize=2.643 # [Angstrom]
binFactor=4


source /programs/sbgrid.shrc
module load mamba
conda activate tomotwin

###DEBUGGING
#export TORCH_LOGS="+dynamo"
#export TORCHDYNAMO_VERBOSE=1

## All the Paceview / File Names for that Tilt Series will be iterated in this for loop.
# Directory containing the files
directory="./"

# Loop through all .rec files in the specified directory
for file in "$directory"/*.rec; do
    # Extract the filename without the path
    filename=$(basename "$file")

    # Extract the prefix before the first underscore
    prefix=$(echo "$filename" | cut -d'_' -f1)

    # Add the prefix to an array
    prefixes+=("$prefix")
done

# Sort the array and get unique values
unique_prefixes=($(echo "${prefixes[@]}" | tr ' ' '\n' | sort | uniq))

for prefix in "${unique_prefixes[@]}"; do

    # Determine Input and Output File Names
    file=''$prefix'_ts_'$(printf %03d $SLURM_ARRAY_TASK_ID)'.mrc.2000.wbp.yz.rec'
    maskName='mask/'$prefix'_ts_'$(printf %03d $SLURM_ARRAY_TASK_ID)'.mrc.2000.wbp.yz_mask.mrc'
    embeddingsName='out/embed/tomo/'$prefix'_ts_'$(printf %03d $SLURM_ARRAY_TASK_ID)'.mrc.2000.wbp.yz_embeddings.temb'
    clusteringName='out/clustering/'$prefix'_ts_'$(printf %03d $SLURM_ARRAY_TASK_ID)'.mrc.2000.wbp.yz_embeddings.tumap'

    #####################################################################################
    if [ -f $file ]; then
        if [ ! -f $maskName ]; then
            # Display I/O
            echo "Reading inputfile: " $file
            # Create Output Directory
            echo "Slurm Task ID: " $SLURM_ARRAY_TASK_ID
            # Estimate the Mask
            tomotwin_tools.py embedding_mask median -i $file -m tomotwin_latest.pth -o mask
        elif [ ! -f $embeddingsName ]; then
            # Calculate the (filtered) embeddings
            tomotwin_embed.py tomogram -m ./tomotwin_latest.pth -v $file --mask $maskName -b 256 -o out/embed/tomo/ -s 4
        elif [ ! -f $clusteringName ]; then
            # # Estimate UMAP manifold and Generate Embedding Mask (Would we need to do this for them all or just one?)
            tomotwin_tools.py umap -i $embeddingsName -o out/clustering/
        fi
    fi

done

wait 