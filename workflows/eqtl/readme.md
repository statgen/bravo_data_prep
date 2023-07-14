# eQTL Data Processing
Process eQTL data into tsv format suitable for import using mongoimport.

## Importing into mongo
Data is in format that is suitable to use [mongoimport](https://www.mongodb.com/docs/database-tools/mongoimport/) tool from MongoDB.
E.g. import consolidated conditional analysis into `eqtl_cond` collection.
```sh
mongoimport \
  --host="localhost" --db="bravo-demo" \
  --type="tsv" --columnsHaveTypes  --headerline \
  --parseGrace=stop --collection=eqtl_cond \
  --file=result/conditional/all.cond.tsv
```
