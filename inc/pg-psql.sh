#!/bin/bash

DB=$1

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/pg-setup.sh

cat | psql -h localhost -U $USER $DB
