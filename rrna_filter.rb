#! /usr/bin/env ruby
# rRNA filtering for FASTQ reads derived from plants

require 'trollop'

# TODO: migrate to Assembler object
# TODO: move all filesystem calls to ruby methods

# options
opts = Trollop::options do
  version "v0.0.1a"
  banner <<-EOS

------------------ filter_rRNA --------------------

filter rRNA-derived reads using bowtie2

---------------------------------------------------

EOS
  opt :left, "left reads file in fastq/fasta format", :required => true, :type => String
  opt :right, "right reads file in fastq/fasta format", :required => true, :type => String
  opt :reference, "path to bowtie2 index of the rRNA reference", :default => '/data/filtering/rRNAplants', :type => String
  opt :threads, "number of threads to use", :default => 6, :type => Integer
end

# construct bowtie command
bowtiecmd = "bowtie2 -p #{opts.threads} --local --quiet #{opts.reference} -1 #{opts.right} -2 #{opts.left} --un-conc norRNA.#{opts.left}"

puts 'filtering rRNA reads with bowtie2'

# run
puts `#{bowtiecmd}`