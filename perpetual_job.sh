#!/bin/bash
#SBATCH --job-name=persistent
#SBATCH --dependency=singleton
#SBATCH --time=00:05:00
#SBATCH --signal=B:SIGUSR1@90

ml purge

# catch the SIGUSR1 signal
_resubmit() {
    ## Resubmit the job for the next execution
    echo "$(date): job $SLURM_JOBID received SIGUSR1 at $(date), re-submitting"
    sbatch $0
}
trap _resubmit SIGUSR1


export PYP_CONFIG=/some/path/config.toml
/hpc/apps/nextpyp/0.5/start

echo "$(date): job $SLURM_JOBID starting on $SLURM_NODELIST"
while true; do
    echo "$(date): normal execution"
    sleep 60
done
