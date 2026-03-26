#!/usr/bin/env bash

# Import script for importing into local development mongo instance
#  Prototype for importing data into staging/prod

DB="bravo"
COLLECTION="sv_aligns"

# Drop existing collection
mongosh --eval "db.${COLLECTION}.drop()" bravo-demo

for FILE in result/sv_summary_chr*.json.gz
do
  echo $FILE

  # Import data
  zcat "${FILE}" |\
    mongoimport "mongodb://localhost" --db=${DB} --collection=${COLLECTION} \
      --parseGrace=stop --stopOnError --type json --jsonArray
done

# INFILE="result/sv_summary_chr11:5219850-5520150.json.gz"
# 
# zcat "${INFILE}" |\
#   mongoimport "mongodb://localhost" --db=bravo --collection=sv_aligns \
#     --parseGrace=stop --stopOnError --type json --jsonArray
