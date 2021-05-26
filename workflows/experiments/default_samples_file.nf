/* Handle Samples File
  
  Samples file channel: file with New_ID\tOld_ID 
    Should be a value channel to permit indefinite re-use.
    Either generated from list of cramps
  Samples info channel:  new_id, old_id, cram, crai
    Either generated from list of crams or parsed from provided samples file.
*/
if(params.samples_file == 'NO_FILE') {
  samples_file_chan = Channel.fromPath(params.cram_files)
                             .map{ "${it.getSimpleName()}\t${it.getSimpleName()}" }
                             .collectFile(name: "generated_samples_list.tsv", newLine: true)
                             .first()

  samples_info_chan = Channel.fromPath(params.cram_files)
                             .map{ 
                               ["${it.getSimpleName()}","${it.getSimpleName()}",file("${it}"),file("${it}.crai")]
                             }
} else {
  samples_file_chan = Channel.fromPath(params.samples_file)
                             .first()

  samples_info_chan = Channel.from(file(params.samples_file).readLines())
                             .map { 
                               line -> def fields = line.split();
                               [fields[0], fields[1], file(fields[2]), file(fields[3])]
                             }
}

process indexes_on_the_side {
  // Using scratch may speed up work on cluster nodes.
  //scratch true

  input:
  file vcf from Channel.fromPath("${params.vcfs_path}").take(10)
  // Included to generate symlinks to index files.
  file csi from Channel.fromPath("${params.vcfs_path}.csi").take(10)

  file samples_file from samples_file_chan

  output:
  stdout into indexes_demo

  script:
  """
  du -l $vcf
  du -l ${vcf}.csi
  """
}

process default_samples_file {

  input:
  //file samples from get_samples_file_channel(samples_file)
  file samples from samples_file_chan

  output:
  stdout into file_demo

  script:
  """
  wc -l $samples
  """
}

process default_samples_info {
  // use take(10) for debugging.
  input:
  tuple val(new_sample_name), val(sample_name), file(cram), file(crai) from samples_info_chan.take(10)

  output:
  stdout into info_demo

  script:
  """
  echo "$new_sample_name, $sample_name"
  du -L $cram
  du -L $crai
  """

}

indexes_demo.view()
