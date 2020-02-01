#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

pgsqlstr=`cat ${VESTA_DIR}/conf/pgsql.conf`
eval $pgsqlstr
export PGPASSWORD=$PASSWORD
