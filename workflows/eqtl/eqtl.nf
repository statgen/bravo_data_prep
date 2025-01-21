process validate_header {
  label "highcpu"

  input:
  file tissue_tsv
  val headers

  output:
  stdout

  script:
  headers
  expected_n_tabs = headers.size() - 1
  expected_header = headers.join('\t')
  """
  # Verify tab delimited expected number of columns
  NTABS=\$(head -n 1 ${tissue_tsv} | grep -o '\t' | wc -l)

  if [[ \$NTABS -ne $expected_n_tabs ]]
  then
    echo "Unexpected number of tabs (\$NTABS) in header of $tissue_tsv)"
    exit 1
  fi

  # Verify column names and order
  HEADER=\$(head -n 1 ${tissue_tsv})
  if [ "\${HEADER}" != "${expected_header}" ]
  then
    echo "Unexpected header content."
    echo "Expected: ${expected_header}"
    echo "Observed: \${HEADER}"
    exit 1
  fi
  """
}

/*
  Strip header row from each file.
  Remove trailing version numbers from Ensemble gene ids (column 1)
  Add tissue origin column as last column.
*/
process munge_files {
  label "highcpu"

  input:
  file tissue_tsv
  val analysis_type

  output:
  file "*.tsv"

  shell:
  tissue_type = tissue_tsv.getFileName().toString().tokenize(".")[0]
  '''
  # Find 1-based index of the variant_id field by in the header
  #  by removing everything after it and counting tabs. (Count tabs before variant_id)
  TAB_CNT=$(head -n 1 !{tissue_tsv} | sed 's/variant_id.*//' | tr -dc '\t' | wc -c)
  ID_COL_IDX=$(($TAB_CNT + 1))

  # Replace the .digit suffix of the ensembl id in col 1
  # Replace underscores with dashes in positional id.
  # Remove chr prefix from positional id.
  # Split positional id into component parts and write as new cols.
  awk -v id_col=${ID_COL_IDX} \
    'BEGIN {FS="\t"; OFS=FS}\
    (NR>1) { \
      sub(/\\.[[:digit:]]+$/, "", $1); \
      gsub(/_/, "-", $id_col); \
      sub(/chr/, "", $id_col); \
      \
      split($id_col, cpra_arr, "-"); \
      for(i=1; i<=length(cpra_arr); i++) $0 = $0 OFS cpra_arr[i]; \
      print $0 OFS "!{tissue_type}" \
    }' !{tissue_tsv} > !{tissue_type}.!{analysis_type}.tsv
  '''
}

/*
  Write header row with typing for mongoimport included.  
    including annotations for columns tissue columns added in munge process:
    chrom, pos, ref, alt, tissue type
  Concatenate all tissue specific files.
*/
process merge_files {
  label "highcpu"

  input:
  file file_list
  val analysis_type
  val fields
  val types

  output:
  file "all.${analysis_type}.tsv"

  publishDir "result/", pattern: "all.${analysis_type}.tsv"

  script:
  outfile = "all.${analysis_type}.tsv"
  mongo_hdr = GroovyCollections.transpose( fields, types)
                .collect{arr -> arr.join(".") + "()"}
                .plus("chrom.string()")
                .plus("pos.int32()")
                .plus("ref.string()")
                .plus("alt.string()")
                .plus("tissue.string()")
                .join("\t")
  """
  echo "$mongo_hdr" > $outfile

  FILES=($file_list)
  for INFILE in \${FILES[@]}
  do
    cat \$INFILE >> $outfile
  done
  """
}

workflow conditional_eqtl {
  analysis_type = "cond"
  cond_tsv      = channel.fromPath("${params.cond_eqtl_glob}")
  cond_headers  = channel.of(params.cond_fields).collect()
  fields        = params.cond_fields
  types         = params.cond_types

  validate_header(cond_tsv, cond_headers)
  munge_files(cond_tsv, analysis_type)
  merge_files(munge_files.out.collect(), analysis_type, fields, types)
}

workflow susie_eqtl {
  analysis_type = "susie"
  susie_tsv     = channel.fromPath("${params.susie_eqtl_glob}")
  susie_headers = channel.of(params.susie_fields).collect()
  fields        = params.susie_fields
  types         = params.susie_types

  validate_header(susie_tsv, susie_headers)
  munge_files(susie_tsv, analysis_type)
  merge_files(munge_files.out.collect(), analysis_type, fields, types)
}

workflow {
  conditional_eqtl()
  susie_eqtl()
}
