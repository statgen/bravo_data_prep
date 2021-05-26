// Example of handling optional input by defining a special value  "NO_FILE"
//   because the arguement of the file function cannot be empty.
params.inputs = '*'
params.samples_path = 'NO_FILE'

process foo {
  echo true

  input:
  // Use a queue channel to process all files throught script.
  file infile from Channel.fromPath(params.inputs)

  // Use a value channel for the samples file so it can be read unlimited times.
  file samples_file from Channel.value( file(params.samples_path) )

  script:
  // Handle optional file parameter
  def samples_opt = samples_file.name == 'NO_FILE' ?  "" : "--filter $samples_file"
  """
  echo --input $infile $samples_opt
  """
}

// nextflow run optional_samples.nf
// nextflow run optional_samples.nf --samples /path/to/samples.txt

