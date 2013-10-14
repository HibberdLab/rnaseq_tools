#!/usr/bin/env ruby

require 'trollop'

opts = Trollop::options do
  version "v0.0.1a"
  banner <<-EOS

--------------- eXpress_sample --------------------

run eXpress for each replicate of a sample, collating
the results into a single CSV file suitable for
importing into R as a data.matrix.

Either --fasta or --bowtieref must be supplied.

Example usage if you have three replicates of sample
"firstsample" and a transcriptome FASTA file:

1. Create a file replicates.txt with contents like:

1_l.fq
1_r.fq
2_l.fq
2_r.fq
3_l.fq
3_r.fq

2. Run eXpress_sample with the command:

eXpress_sample --pairedfile replicates.txt \
               --reference reference.fasta \
               --samplename firstsample

---------------------------------------------------

EOS
  opt :pairedfile, "path to text file containing list of paired-end read FASTQ files, one per line, left then right, one replicate per two lines", :required => true, :type => String
  opt :fasta, "path to FASTA file for reference transcriptome", :required => true, :type => String
  opt :bowtieref, "path to Bowtie index for reference transcriptome", :type => String
  opt :samplename, "name to use as prefix for this sample", :type => String
  opt :threads, "number of threads to use", :default => 8, :type => Integer
end

bowtieref = nil

# Check the reference input
if opts.fasta
  unless File.exists? opts.fasta
    raise "Reference FASTA file does not exist at path: #{opts.fasta}"
  end

  unless opts.bowtieref
    # construct the bowtie reference
    puts "No bowtie reference supplied; constructing now..."
    bowtieref = File.basename(opts.fasta)
    if File.exists? "#{bowtieref}.1.ebwt"
      puts "reference exists in current directory - reusing"
    else
      `bowtie-build --offrate 1 #{opts.fasta} #{bowtieref}`
    end
  end
end

if opts.bowtieref
  unless File.exists? "#{opts.bowtieref}.1.ebwt"
    raise "Reference Bowtie index does not exist at path: #{opts.bowtieref}"
  end
  bowtieref = opts.bowtieref
end

# Parse in the input files
readfiles = File.open(opts.pairedfile).each.map { |line|
  File.expand_path(line.chomp)
}.each_slice(2).to_a



# Process the replicates
outfiles = []
readfiles.each_with_index do |pair, index|
  left, right = pair
  puts "running for replicate ##{index+1}"
  # construct express command
  cmd = "bowtie -p #{opts.threads} -aS -X 800 --offrate 1"
  cmd += " #{bowtieref}"
  cmd += " -1 #{left}"
  cmd += " -2 #{right}"
  cmd += "| express #{opts.fasta}"
  puts "running command:"
  puts cmd

  outfile = "#{opts.samplename}.#{index+1}.xprs"
  unless File.exist? outfile
    `#{cmd}`
    File.rename('results.xprs', outfile)
  end
  outfiles << outfile
  puts "output written to #{outfile}"
end

# Collate the data
require 'csv'
puts "collating the results..."
collated = {}
outfiles.each_with_index do |outfile, index|
  CSV.open(outfile, {:col_sep => "\t", :headers => true}).each do |row|
    collated[row[1]] ||= []
    collated[row[1]][index] = row[7]
  end
end

collated_file = "#{opts.samplename}.results.xprs"
puts "writing collated data to #{collated_file}"
CSV.open(collated_file, "w") do |out|
  out << ['target_id'] + (1..outfiles.size).to_a
  collated.each_pair do |target_id, data|
    out << [target_id] + data
  end
end
