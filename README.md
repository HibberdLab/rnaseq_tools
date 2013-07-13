rnaseq_tools
============

Miscellaneous tools for analysis of RNA-seq and transcriptomic data.

## Batch read processing scripts

* **khmer-batch** - run digital normalisation on a series of FASTQ read files, preserving the kmer counting hash between runs, to create a single normalised read dataset.
* **trim-batch** - run trimmomatic on a series of FASTQ read files, optionally trimming paired and single reads in the same run.