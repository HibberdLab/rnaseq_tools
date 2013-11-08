RNASeq tools
============

A collection of tools for analysis of RNA-seq and transcriptomic data used by the [Hibberd Lab](http://hibberdlab.github.io).

### setup

Scripts for organising raw data, for example by processing data downloaded from sequencing services to concatenate and name files by sample. 

* **prepare_samples_TGAC.rb** - parses the TGAC SampleAlias.txt file and concatenates and renames gzipped FASTQ files by sample name.

### preprocess

* **trim-batch** - run trimmomatic on a series of FASTQ read files, optionally trimming paired and single reads in the same run. After quality analysis, this is the first step in an RNASeq pipeline.
  - todo:
    - run multiple trimmomatic processes in parallel
* **khmer-batch** - run digital normalisation on a series of FASTQ read files, preserving the kmer counting hash between runs, to create a single normalised read dataset. Useful for incorporating a new read dataset with old data to generate an improved *de-novo* assembly.
  - todo:
    - add option to use filter-by-abund

### expression

* **express_sample.rb** - run eXpress on each replicate of a sample, collating results into a single CSV.
* **sailfish_sample.rb** - run Sailfish on each replicate of a sample, collating results into a single CSV.
* **EBSeq_experiment.R** - run differential expression analysis using EBSeq.
* **GO_analyse.R** - run GO term enrichment analysis.
* **plot_GO_analysis.R** - generate plots of GO term analysis, including a representation of replative enrichment between samples, and which genes are important in each category.

## License

All files released under the permissive MIT 'Expat' license unless otherwise specified.

[![Read about open source licenses](http://opensource.org/trademarks/osi-certified/web/osi-certified-120x100.png)](http://opensource.org/docs/definition.php)