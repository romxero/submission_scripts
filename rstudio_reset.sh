#!/bin/bash

## This script will try to reset Rstudio, so it wont hang on startup?
##
##
ml purge 
ml load R/4.3 

pushd ~
# remove stored data file and history
rm -rf .RData .Rhistory

# move the Rstudio config files to a backup location
mv ~/.local/share/rstudio ~/.local/share/rstudio-backup
mv ~/.config/RStudio ~/backup-RStudio

# run this method to clean up the Rstudio session
Rscript <(echo "gc(); gctorture(FALSE);")

popd 
