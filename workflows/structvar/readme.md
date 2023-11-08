# Structural Variant Data Processing

## Make Sites Only Dataset
Process genotyped struct var data to 'sites only' using empty samples list.
Produce gzipped tsv file to be re-headered and imported into mongo

```sh
bcftools query -s '' -f '%CHROM\t%POS\%REF%\t%INFO/SVTYPE\t%INFO/SVLEN\n' | gzip - > struct_var.tgz
```

## Mongo Import Sites Only Struct Variants Data

```sh
mongoimport --db=bravo-demo --collection=structvar --gzip --columnsHaveTypes --headerline \
  --parseGrace=stop --stopOnError --type tsv struct_import.tsv.gz
```
