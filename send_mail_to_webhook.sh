#!/bin/bash
#SBATCH -J "send_msgto_webhook"
#SBATCH --time=00:02:00
#SBATCH -c 1
#SBATCH -p preview
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mem=1G
#SBATCH --output=send_msgto_webhook_%A.%a.out
#SBATCH --error=send_msgto_webhook_%A.%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=randall.white@czbiohub.org
##SBATCH -D /home/randall.white/Documents/code/next_pyp_builds/shared

#write something to a web hook
#url of the webhook destination
MY_URL=''
#http header
MY_HTTP_HEADER="Content-Type: application/json"
#message
MY_MESSAGE="Hello there \
We are trying to make this a good messsagee \
I hope You are having a good dayy"

#json msg payload
MESSAGE_PAYLOAD="{\"text\": \"$MY_MESSAGE\" }"

curl -d "${MESSAGE_PAYLOAD}" -H "${MY_HTTP_HEADER}" -X POST "${MY_URL}"

wait 
