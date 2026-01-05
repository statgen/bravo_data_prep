#!/usr/bin/env bash

# Import script for importing into local development mongo instance
#  Prototype for importing data into staging/prod

# Drop existing collection
# mongosh --eval 'db.sv_reads.drop()' bravo-demo

for FILE in result/sv_summary_chr*.json.gz
do
  echo $FILE

  # Import data
  # zcat "${FILE}" |\
  #   mongoimport "mongodb://localhost" --db=bravo-demo --collection=sv_reads \
  #     --parseGrace=stop --stopOnError --type json
done

zcat result/sv_summary_chr7:5219850-5520150.json.gz |\
  mongoimport "mongodb://localhost" --db=bravo-demo --collection=sv_aligns \
    --parseGrace=stop --stopOnError --type json --jsonArray
