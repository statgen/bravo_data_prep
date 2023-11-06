#!/usr/bin/env bash

FMT_STR='%CHROM\t%POS\t%REF\t%INFO/SVTYPE\t%INFO/SVLEN\n'
INFILE=data/structural.variant.1.1.genotypes.bcf

# Process topmed structvar bcf into a tsv of relevant data
# Requires access to the topmed exchange area
# bcftools query -f "${FMT_STR}" data/structural.variant.1.1.genotypes.bcf |\
#   gzip - > struct_var.tgz

# Create mongo import tool compatible header
HEADER="chrom.string()\tpos.int()\tref.string()\tvar_type.string()\tvar_len.int()"

echo -e "${HEADER}" > struct_import.tsv
zcat struct_var.tgz >> struct_import.tsv
gzip -f struct_import.tsv 
