#!/usr/bin/env bash

# Import script for importing into local development mongo instance
#  Prototype for importing data into staging/prod

INFILE=result/structvar_list.tsv.gz
# Drop existing collection
mongosh --eval 'db.sv_list.drop()' bravo-demo

# Import data
zcat "${INFILE}" |\
  mongoimport --db=bravo --collection=sv_list --columnsHaveTypes --headerline \
    --parseGrace=stop --stopOnError --type tsv
