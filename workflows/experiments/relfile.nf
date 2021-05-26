// Relative paths are from where nextflow was invoked.
// invoking this as `nextflow run relfile.nf` works, but
//  running from the a directory up does not.
process relfile {

  input:
  file data_file from Channel.fromPath('data/notes.md', relative: true)

  output:
  stdout into demo

  script:
  """
  wc -l $data_file
  """
}

demo.view()
