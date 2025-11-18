# Structural Variant Data Processing
The structural variant data has three components: listing, reads, and coverage.

## Structural Variants: List
Derived directly from the structural variants bcf.
Taking the variant id, type, and length

### Make Sites Only Dataset
Process genotyped struct var data to 'sites only' using empty samples list.
Produce gzipped tsv file to be re-headered and imported into mongo

```sh
bcftools query -s '' -f '%CHROM\t%POS\%REF%\t%INFO/SVTYPE\t%INFO/SVLEN\n' | gzip - > struct_var.tgz
```

### Mongo Import Sites Only Struct Variants Data

```sh
mongoimport --db=bravo-demo --collection=structvar --gzip --columnsHaveTypes --headerline \
  --parseGrace=stop --stopOnError --type tsv struct_import.tsv.gz
```

## Structural Variants: Reads
Transform cram files into a samplot-like data format.

## Structural Variants: Coverage
Binned pileup same as BRAVO's background data.
