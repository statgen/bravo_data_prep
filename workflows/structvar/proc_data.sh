#!/usr/bin/env bash

FMT_STR='%CHROM\t%POS\t%REF\t%INFO/SVTYPE\t%INFO/SVLEN%INFO/END\n'
INFILE=data/structural.variant.1.1.genotypes.bcf

###############
# Subset data #
###############

# Process topmed structvar bcf into a tsv of relevant data
# Requires access to the topmed exchange area
# bcftools query -f "${FMT_STR}" data/structural.variant.1.1.genotypes.bcf |\
#   gzip - > struct_var.gz

################
# Process data #
################

# Add header with types for mongo import
# Remove chr from chromosome to match rest of data

HEADER="chrom.string()\tpos.int64()\tref.string()\tsv_type.string()\tsv_len.int32()\tend.int64()\tac.int32()\tan.int32()\tpre.string()\tpost.string()"

read -r -d '' AWK_SCRIPT <<'HEREDOC'
BEGIN { 
  OFS = FS
  print header 
}
{ $1 = substr($1, 4, 2); print $0}
HEREDOC

zcat struct_var.gz |\
  awk -F $"\t" -v header="${HEADER}" "${AWK_SCRIPT}" |\
  gzip - > struct_import.gz
