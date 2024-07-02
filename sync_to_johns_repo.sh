#!/bin/bash

set -x

GRIZNOG_REPO_LOC="/Users/randall.white/Documents/code/griznog_repos/hpc-user-guide"
RC_REPO_LOC="/Users/randall.white/Documents/code/bruno-hpc-docs"


# begin the sync stuff right here:
rsync -avz --progress --exclude '.git' --exclude '.gitignore' --exclude 'sync_to_johns_stuff.sh' ${RC_REPO_LOC}/* ${GRIZNOG_REPO_LOC}/

#end


exit 0
