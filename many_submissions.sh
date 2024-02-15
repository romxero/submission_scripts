#!/bin/bash

#for the returned job id
MY_RETURNED_JOBID=''
MY_FILTERED_JOBID=''

#Length of all arrays.
ARR_LEN=9

#SHM_LOCATION
MY_SHM_LOCATION=/dev/shm/${USER}/submission_scripts_$(uuidgen)

#TEMPLATING VARIABLES
TEMP_VARS_0=(
paceview12_ts_001.mrc.2000.wbp.yz.trimmed.rec
paceview12_ts_002.mrc.2000.wbp.yz.trimmed.rec
paceview12_ts_003.mrc.2000.wbp.yz.trimmed.rec
paceview12_ts_005.mrc.2000.wbp.yz.trimmed.rec
paceview9_ts_004.mrc.2000.wbp.yz.trimmed.rec 
paceview11_ts_004.mrc.2000.wbp.yz.trimmed.rec
paceview10_ts_005.mrc.2000.wbp.yz.trimmed.rec
grid4view2_ts_008.mrc.2000.wbp.yz.trimmed.rec
paceview11_ts_007.mrc.2000.wbp.yz.trimmed.rec
)

TEMP_VARS_1=(
paceview12_ts_001.mrc.rawtlt
paceview12_ts_002.mrc.rawtlt
paceview12_ts_003.mrc.rawtlt
paceview12_ts_005.mrc.rawtlt
paceview9_ts_004.mrc.rawtlt
paceview11_ts_004.mrc.rawtlt
paceview10_ts_005.mrc.rawtlt
grid4view2_ts_008.mrc.rawtlt
paceview11_ts_007.mrc.rawtlt
)

# ROC VARIABLES 
ROC_VARS_0=(
paceview11_ts_007.mrc.2000.wbp.yz_job.jso
paceview12_ts_001.mrc.2000.wbp.yz_job.jso
paceview12_ts_002.mrc.2000.wbp.yz_job.jso
paceview12_ts_003.mrc.2000.wbp.yz_job.jso
paceview12_ts_005.mrc.2000.wbp.yz_job.js
paceview9_ts_004.mrc.2000.wbp.yz_job.jso
paceview11_ts_004.mrc.2000.wbp.yz_job.jso
paceview10_ts_005.mrc.2000.wbp.yz_job.jso
grid4view2_ts_008.mrc.2000.wbp.yz_job.json
)

ROC_VARS_1=(
paceview11_ts7_roc.log
paceview12_ts1_roc.log
paceview12_ts2_roc.log
paceview12_ts3_roc.log
paceview12_ts5_roc.log
paceview9_ts4_roc.log
paceview11_ts4_roc.log
paceview10_ts5_roc.log
grid4view2_ts8_roc.log
)



##################################################
#make sure this location exists first
mkdir -p ${MY_SHM_LOCATION}

# Do the Templating
for iter in  $(seq 1 $ARR_LEN)
do 

cat << EOD > ${MY_SHM_LOCATION}/templatmatch_${iter}.sh 
#!/bin/bash
#SBATCH --nodes=1 
#SBATCH --gpus=4 
#SBATCH --constraint='a100_40|a100_80'
#SBATCH --time=3-00:00:00 
#SBATCH --mem=40G 
#SBATCH --job-name=templatematching_${iter}
#SBATCH --output=tm_RPbin4_trimoutputs/output_%A_%a.out 
#SBATCH --error=tm_RPbin4_trimoutputs/output_%A_%a.err 
mkdir -p tm_RPbin4_trimoutputs/ 
set -x 
ml purge 
cd /hpc/projects/group.czii/reza.paraan/UCSF_krios1/20231109/20231109_Bin4_alldeconv 
module load anaconda/latest 
conda activate pytom_tm 
pytom_match_template.py -t templates/VATPase_RP_ctf_10.56Apix_trans.mrc -m templates/mask_10.56Apix.mrc -v ${TEMP_VARS_0[$iter]} -d results_RP_3deg_weightwhite/ -a rawtlt/${TEMP_VARS_1[$iter]} --angular-search 3.00 --voxel-size 10.56 --low-pass 22 -g 0 1 2 3 --per-tilt-weighting --spectral-whitening
EOD


MY_RETURNED_JOBID=$( sbatch ${MY_SHM_LOCATION}/templatmatch_${iter}.sh )


sleep 2
done 



MY_FILTERED_JOBID=$(echo $MY_RETURNED_JOBID | sed 's/Submitted batch job /''/g')


# Do ROC
for iter in  $(seq 1 $ARR_LEN)
do 
cat << EOD > ${MY_SHM_LOCATION}/roc_templatmatch_${iter}.sh 
#!/bin/bash
#SBATCH --nodes=1 
#SBATCH --gpus=4 
#SBATCH --dependency=afterok:${MY_FILTERED_JOBID}
#SBATCH --constraint='a100_40|a100_80'
#SBATCH --time=3-00:00:00 
#SBATCH --mem=40G 
#SBATCH --job-name=roc_templatematching_${iter}
#SBATCH --output=tm_RPbin4_trimoutputs/output_%A_%a.out 
#SBATCH --error=tm_RPbin4_trimoutputs/output_%A_%a.err 
mkdir -p tm_RPbin4_trimoutputs/ 
set -x 
ml purge 
cd /hpc/projects/group.czii/reza.paraan/UCSF_krios1/20231109/20231109_Bin4_alldeconv 
module load anaconda/latest 
conda activate pytom_tm 
pytom_estimate_roc.py -j results_RP_3deg_weightwhite/${ROC_VARS_0[$iter]} -n 100 -r 8 --bins 16 --crop-plot  > results_RP_3deg_weightwhite/${ROC_VARS_1[$iter]}
EOD


MY_RETURNED_JOBID=$( sbatch ${MY_SHM_LOCATION}/roc_templatmatch_${iter}.sh )

sleep 2
done 

