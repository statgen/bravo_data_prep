# eQTL Data Processing
Process eQTL data into tsv format suitable for import using mongoimport.

## Importing into mongo
Data is in format that is suitable to use [mongoimport](https://www.mongodb.com/docs/database-tools/mongoimport/) tool from MongoDB.

E.g. import consolidated conditional analysis into `eqtl_cond` collection.
```sh
mongoimport \
  --host="localhost" --db="bravo-demo" --drop \
  --type="tsv" --columnsHaveTypes  --headerline \
  --parseGrace=stop --collection=eqtl_cond \
  --file=result/all.cond.tsv
```

E.g. import consolidated susie analysis into `eqtl_cond` collection.
```sh
mongoimport \
  --host="localhost" --db="bravo-demo" --drop \
  --type="tsv" --columnsHaveTypes  --headerline \
  --parseGrace=stop --collection=eqtl_susie \
  --file=result/all.susie.tsv
```
