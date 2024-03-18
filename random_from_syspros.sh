#!/bin/bash

if [ ! -z "$PS1" ]; then
  SLURM_ACCOUNTS=$(sacctmgr show assoc format=account user=$USER --parsable2 --noheader | sort | uniq)
  if [ ! -z "${SLURM_ACCOUNTS}" ]; then
    echo "Job submission accounts you have access to:"
    echo " $(echo ${SLURM_ACCOUNTS})"
  fi
  FOLDERS=""
  for ACCOUNT in ${SLURM_ACCOUNTS}; do
    for FOLDER in projects classes; do
      if [ -r /work/${FOLDER}/${ACCOUNT} ]; then
        FOLDERS="${FOLDERS} /work/${FOLDER}/${ACCOUNT}"
      fi
    done
  done
  if [ ! -z "${FOLDERS}" ]; then
    echo "Group storage folders you have access to:"
    echo "${FOLDERS}"
  fi
  if [ -z "${SLURM_ACCOUNTS}" -a -z "${FOLDERS}" ]; then
    echo "You have no job accounts or group storage folders.\nContact your research advisor or course instructor."
  fi
fi