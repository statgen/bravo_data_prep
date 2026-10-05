# Depth of Coverage Workflow
Calculate the read depth for various base pair widths (bin widths)

## Requires
Following executeables need to be findable in the PATH.  
On the slurm cluster, these should be provided by modules. 

- samtools
- bam
- bgzip
- tabix
- aggregate.py
- prune.py

## Cram File Inputs
The cram files used in the pipeline should be symlinked under the data/crams directory.
This facilitates aggregating crams from multiple sources or projects.
It avoids having multiple or complex globs in the nextflow.config.

## Preparation 
- Symlinks to reference: taken care of by ansible deployment.
- Symlinks to bcfs: Use same bcfs as process_bcf workflow.
- Symlinks to crams: Use same crams as coverage workflow.

The symlinks to bcfs and crams still done manually or by some script in `hacks/`

## Running

Interactively on  SLURM:
```sh
nextflow run depth_statistics.nf -with-report cov_report.html -profile slurm
```

Run in background on SLURM:
```sh
nextflow run depth_statistics.nf -with-report cov_report.html -profile slurm -ansi-log false -bg > coverage.log
```
For shared clusters, it would be better practice to have a wrapper to submit the nextflow run as a slurm job.
That would avoid putting load on the login node.
Since this is a single purpose cluster, isn't an issue.

## Results
Produces full depth data at resolution of single base pair coverage.
Produces binned depth data that groups bases into bins of similar median and mean depths.
  The threshold for grouping adjacent depths together is indicated in the bin name.
  E.g. bin_0.25 is binning sequential base pairs together until the mean depth differs by .25 or more.
