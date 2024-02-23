#!/bin/bash 

# Random port

function create_random_port ()
{

    local MAX_PORT=65535
    local SET_PORT_START=60000

    PORT_DIFFERENCE=$((${MAX_PORT} - ${SET_PORT_START}))
    VALS=($(seq 60000 65535))

    echo ${VALS[$((($RANDOM + $PORT_DIFFERENCE) % 5535))]}

}
