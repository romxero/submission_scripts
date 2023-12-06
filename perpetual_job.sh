#!/bin/bash
#SBATCH -J "persistent_nextpyp_job"
#SBATCH --signal=B:SIGUSR1@90
#SBATCH --time=4-00:00:00
#SBATCH -c 2 
#SBATCH -p cpu
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mem=4G
#SBATCH --output=persistent_nextpyp_job_%A.%a.out
#SBATCH --error=persistent_nextpyp_job_%A.%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=randall.white@czbiohub.org
##SBATCH -D /home/randall.white/hpc/spack 

# catch the SIGUSR1 signal
_resubmit() {
    ## Resubmit the job for the next execution
    echo "$(date): job $SLURM_JOBID received SIGUSR1 at $(date), re-submitting"
    sbatch $0
}

#make sure to export the function 
export -f _resubmit

#trap the signal
trap _resubmit SIGUSR1


#main logic begins 
ml purge

#will need to clear nextpyp
#ml nextpyp

#Message for launching the job 
MY_DATE=$(date -R)
MY_FQDN_HOSTNAME=$(hostname -f)
MY_HOSTNAME=$(echo ${MY_FQDN_HOSTNAME} | cut -d '.' -f 1)
MY_SHORT_MESSAGE="NextPYP job starting on host: ${MY_FQDN_HOSTNAME}, on this date: ${MY_DATE}"
PYP_CONFIG=~/.config.toml
PYP_CONTAINER_LOCATION="/home/randall.white/Documents/code/next_pyp_builds/pyp.sif"
PYP_WEB_LOCAL_DIR="/home/randall.white/Documents/code/next_pyp_builds/local"
PYP_WEB_SHARED_DIR="/home/randall.white/Documents/code/next_pyp_builds/shared"
PYP_WEB_WORKFLOWS_DIR="/home/randall.white/Documents/code/next_pyp_builds/workflows"
PYP_REMOTE_PORT=8080
PYP_LOCAL_PORT=8080

#configure the toml file here on the fly  
cat << EOF > ${PYP_CONFIG}
[pyp]
container = '/home/randall.white/Documents/code/next_pyp_builds/pyp.sif'
scratch = '/tmp/pyp_rcwhite'

[slurm]
user = '${USER}'
host = '${MY_HOSTNAME}
memoryPerNode = '${SLURM_MEM_PER_NODE}'
cpusPerNode = '${SLURM_CPUS_ON_NODE}'

[web]
localDir = '${PYP_WEB_LOCAL_DIR}'
sharedDir = '${PYP_WEB_SHARED_DIR}'
webhost = 'https://${MY_HOSTNAME}'
workflowDirs = ['${PYP_WEB_WORKFLOWS_DIR}']
EOF

#exporting the configuration toml

#send an email and create a log entry that the job is ready 
echo ${MY_SHORT_MESSAGE} | mailx -s "subject" randall.white@czbiohub.org
logger -s ${MY_SHORT_MESSAGE}


export PYP_CONFIG
/hpc/apps/nextpyp/0.5/start & 


#Wait until job submits until I can exit out of the menu
echo "You will want to connect to this with a port-forwarding scheme in ssh"
echo "ssh -A -L ${PYP_LOCAL_PORT}:${MY_FQDN_HOSTNAME}:${PYP_REMOTE_PORT} login-02.czbiohub.org"

#main logic ends 
echo "$(date): job $SLURM_JOBID starting on $SLURM_NODELIST"
while true; do
    echo "$(date): normal execution"
    sleep 60
done

# wait till the script completely finishes 
wait 
