#!/bin/bash

## This script will try to reset Rstudio, so it wont hang on startup?
##
##
ml purge 

# please change this to the respective R version. 
ml load R/4.3 


reset_rstudio_env () {

pushd ~
# remove stored data file and history
# remove the Rstudio-Desktop state file

if [ -f .RData ]; then
  rm .RData
fi

if [ -f .Rhistory ]; then
  rm .Rhistory
fi


# move the Rstudio config files to a backup location

if [ -d ~/.local/share/rstudio ]; then
  mv ~/.local/share/rstudio ~/.local/share/rstudio-backup
fi



if [ -d ~/.config/RStudio ]; then
  
mv ~/.config/RStudio ~/backup-RStudio

fi



if [ -d ~/.config/rstudio ]; then
  
mv ~/.config/rstudio/ ~/backup-rstudio

fi


# run this method to clean up the Rstudio session
Rscript <(echo "gc(); gctorture(FALSE);")

popd 



}


reset_rstudio_env