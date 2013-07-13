RNASeq tools
============

A collection of tools for analysis of RNA-seq and transcriptomic data used by the [Hibberd Lab](http://hibberdlab.github.io).

## Batch read processing scripts

* **trim-batch** - run trimmomatic on a series of FASTQ read files, optionally trimming paired and single reads in the same run. After quality analysis, this is the first step in an RNASeq pipeline.
* **khmer-batch** - run digital normalisation on a series of FASTQ read files, preserving the kmer counting hash between runs, to create a single normalised read dataset. Useful for incorporating a new read dataset with old data to generate an improved *de-novo* assembly.


## License

All files released under the permissive MIT 'Expat' license unless otherwise specified.

[![Read about open source licenses](http://opensource.org/trademarks/osi-certified/web/osi-certified-120x100.png)](http://opensource.org/docs/definition.php)