#!/usr/bin/env bash

# Import script for importing into local development mongo instance
#  Prototype for importing data into staging/prod

# Drop existing collection
mongosh --eval 'db.structvar.drop()' bravo-demo

# Import data
zcat result/struct_import.gz |\
  mongoimport --db=bravo-demo --collection=structvar --columnsHaveTypes --headerline \
    --parseGrace=stop --stopOnError --type tsv
