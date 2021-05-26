// Path glob to get both the bcf and the index files as pairs
params.vcfs_glob = "data/vcfs/*.{bcf,bcf.csi}"

process demo{
  input:
  tuple val(id), file(vcf), file(idx) from Channel.fromFilePairs(params.vcfs_glob, flat: true)

  output:
  stdout into demo

  script:
  """
  echo $vcf : $idx
  """
}

demo.view()
