#!/bin/bash
## 03/07/24
## start spid jupyter

#note that the container already pretty much creates the directories, just make sure to bind `/hpc` and pass --nv to use gpus

#container location
CONTAINER_FULL_PATH='/hpc/apps/spid/master/bin/spid_container.sif'

#noteboook location to launch everything 
SPID_CACHE_DIR=${HOME}/.spid_cache
if ! [ -d ${SPID_CACHE_DIR} ]; then
    mkdir -p ${SPID_CACHE_DIR}
fi

NOTEBOOK_ROOT=${HOME}

function create_random_port () 
{

    local MAX_PORT=65535
    local SET_PORT_START=38999

    PORT_DIFFERENCE=$((${MAX_PORT} - ${SET_PORT_START}))
    VALS=($(seq 60000 65535))

    echo ${VALS[$((($RANDOM + $PORT_DIFFERENCE) % $PORT_DIFFERENCE))]}

}



MY_PORT=$(create_random_port)

# create server config
export CONFIG_FILE="${PWD}/config.py"
(
umask 077
cat > "${CONFIG_FILE}" << EOL
c.NotebookApp.ip = '*'
c.NotebookApp.port = ${MY_PORT}
c.NotebookApp.port_retries = 0
c.NotebookApp.allow_origin = '*'
c.NotebookApp.notebook_dir = "${NOTEBOOK_ROOT}"
c.NotebookApp.disable_check_xsrf = True
EOL
)


echo "Starting SPID Container w/ Jupyter Notebook"

apptainer exec --writable-tmpfs --nv --bind /hpc:/hpc ${CONTAINER_FULL_PATH} jupyter notebook --config="${CONFIG_FILE}"

exit 0 



