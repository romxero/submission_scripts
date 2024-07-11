#!/bin/bash
#SBATCH -J "czii_large_copy"
#SBATCH --time=14-00:10:00
#SBATCH -c 16
#SBATCH --mem=24G
#SBATCH -n 1
#SBATCH -p dtn,cpu
#SBATCH -N 1
#SBATCH --output=czii_large_copy_%A_%a.out
#SBATCH --error=czii_large_copy_%A_%a.err
#SBATCH --mail-type=START,END,FAIL
#SCRON --dependency=singleton
#SBATCH --dependency=
##SBATCH --mail-user=yue.yu@czbiohub.org





# THIS SHOULD RUN ON BRUNO via `sbatch`
## 
### global variables
MY_SERVER=czii-login-1.czbiohub.org
MY_KEY_FILE=$HOME/data_transfer_key

lftp -u $USER,DUMMY -e "mirror -p --use-cache --verbose=1 -c --parallel=4 --use-pget=4 /hpc/projects/group.czii/krios1.processing /hpc/projects/group.czii/krios1.processing; quit" sftp://${MY_SERVER}

exit 0



setfacl -R -d -m g:group.czii:rwx /hpc/projects/group.czii/krios1.processing