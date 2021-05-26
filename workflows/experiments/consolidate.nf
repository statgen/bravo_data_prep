// Make text file list of: id /path/to/id.cram
// Use Reduce to return a value Channel.
Channel
	.fromPath('data/crams/*.cram')
  .map{ "${it.getSimpleName()} ${it}" }
  .collectFile(name: "cram_files_list.txt", newLine: true)
  .reduce { it -> it }

