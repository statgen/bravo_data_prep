#!/usr/bin/env bash

# Drop existing collection
mongo --eval 'db.structvar.drop()' bravo-demo

# Import data
zcat struct_import.tgz |\
  mongoimport --db=bravo-demo --collection=structvar --columnsHaveTypes --headerline \
    --parseGrace=stop --stopOnError --type tsv
