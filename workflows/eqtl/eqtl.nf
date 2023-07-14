process validate_cond_header {
  label "highcpu"

  input:
  file tissue_tsv

  output:
  stdout

  script:
  expected_n_tabs = params.cond_fields.size() - 1
  expected_header = params.cond_fields.join('\t')
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
  Remove trailing version numbers from Ensemble gene ids
  Add tissue origin column
*/
process munge_cond_files {
  label "highcpu"

  input:
  file tissue_tsv

  output:
  file "*.cond.tsv"

  publishDir "intermediates/conditional/", pattern: "*.cond.tsv"

  shell:
  tissue_type = tissue_tsv.getFileName().toString().tokenize(".")[0]
  '''
  awk 'BEGIN {FS="\t"; OFS=FS}\
    (NR>1) { sub(/\\.[[:digit:]]+$/,"",$1); \
    print $0 OFS "!{tissue_type}" }' !{tissue_tsv} > !{tissue_type}.cond.tsv
  '''
}

process merge_cond_files {
  label "highcpu"

  input:
  file file_list

  output:
  file "all.cond.tsv"

  publishDir "result/conditional/", pattern: "all.cond.tsv"

  script:
  mongo_hdr = GroovyCollections.transpose( params.cond_fields, params.cond_types)
                .collect{arr -> arr.join(".") + "()"}
                .plus("tissue.string()")
                .join("\t")
  """
  echo "$mongo_hdr" > all.cond.tsv

  FILES=($file_list)
  for INFILE in \${FILES[@]}
  do
    cat \$INFILE >> all.cond.tsv
  done
  """
}

workflow {
  tissue_tsv = channel.fromPath("${params.cond_eqtl_glob}")

  validate_cond_header(tissue_tsv)
  munge_cond_files(tissue_tsv)
  merge_cond_files(munge_cond_files.out.collect())
}
