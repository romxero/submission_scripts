#!/usr/bin/env bash

set -x

echo "Script starting..."
echo "Waiting for RStudio Server to open port ${port}..."
echo "TIMING - Starting wait at: $(date)"

setup_env () {
  export RSTUDIO_SERVER_IMAGE="/home/aymane/Scripts/RStudio/rstudio-server.sif"
  export SINGULARITY_BINDPATH="/etc,/media,/mnt,/opt,/srv,/usr,/var"
  export PATH="$PATH:/usr/lib/rstudio-server/bin"
}
setup_env

# Set up a temporary directory for RStudio Server in /tmp
#MY_PRE_TMP=$(mktemp -d -t rstudio_${USER}_server-XXXX)

export MY_TMP_DIR=$(mktemp -d -t rstudio_${USER}_server-XXXX)
mkdir -p $MY_TMP_DIR/var/lib/rstudio-server
mkdir -p $MY_TMP_DIR/var/run/rstudio-server

cat /proc/sys/kernel/random/uuid > "$MY_TMP_DIR/var/run/rstudio-server/secure-cookie-key"
chmod 0600 "$MY_TMP_DIR/var/run/rstudio-server/secure-cookie-key"

export RSTUDIO_DB_FILE="$MY_TMP_DIR/var/lib/rstudio-server/rstudio-os.sqlite"
touch $RSTUDIO_DB_FILE
chmod 0600 $RSTUDIO_DB_FILE

echo "Starting up rserver..."

singularity exec --bind $MY_TMP_DIR/var/lib/rstudio-server:/var/lib/rstudio-server \
  --bind $MY_TMP_DIR/var/run/rstudio-server:/var/run/rstudio-server \
  --home /home/oodadmin:/home/oodadmin \
  $RSTUDIO_SERVER_IMAGE \
  /usr/lib/rstudio-server/bin/rserver \
  --auth-none 1 \
  --www-port=${port} \
  --secure-cookie-key-file=/var/run/rstudio-server/secure-cookie-key \
  --database-config-file=/var/lib/rstudio-server/rstudio-os.sqlite &

sleep 5

echo 'Singularity has exited...'

echo "Waiting for RStudio Server to open port ${port}..."
timeout 60 sh -c 'until nc -z localhost ${port}; do sleep 1; done'

if ! nc -z localhost ${port}; then
  echo "Timed out waiting for RStudio Server to open port ${port}!"
  
  echo "Capturing log files for debugging:"
  if [ -f "${MY_TMP_DIR}/rsession.log" ]; then
    echo "Content of rsession.log:"
    cat "${MY_TMP_DIR}/rsession.log"
  else
    echo "rsession.log not found."
  fi
  
  if [ -f "${HOME}/.local/share/rstudio/log/rserver.log" ]; then
    echo "Content of rserver.log:"
    cat "${HOME}/.local/share/rstudio/log/rserver.log"
  fi
  exit 1
else
  echo "RStudio Server is running on port ${port}"
fi