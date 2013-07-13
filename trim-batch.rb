#!/usr/bin/env ruby

#
# trim-batch
#
# Take in a set of fastq files and run khmer trimmomatic on each
#
# You MUST specify the location of the trimmomatic JAR
#
# Richard Smith (rds45@cam.ac.uk)
#

require 'rubygems'
require 'trollop'

TRIMPREFIX = 't.'

opts = Trollop::options do
  version "v0.0.1a"
  banner <<-EOS
trim-batch: run trimmomatic on multiple fastq files.

Single-end and/or paired-end can be included.
Trimmed files are outputted as '#{TRIMPREFIX}<input filename>'.

Make sure Trimmomatic is installed
EOS
  opt :pairedfile, "A file of paired-end FASTQ file paths, 1 per line, paired files in F, R order", :type => String
  opt :paired, "A list of colon separated paired input FASTQ file paths, paired files in F, R order", :type => String
  opt :singlefile, "A file of single-end FASTQ file paths, 1 per line", :type => String
  opt :single, "A list of colon separated single-end input FASTQ file paths", :type => String
  opt :jar, "Location of the trimmomatic jar file", :required => true, :type => String
  opt :adapters, "Path to adapter FASTA file. If provided, adapters will be trimmed", :type => String
  opt :leading, "Minimum quality required to keep a leading base", :default => 15, :type => Integer
  opt :trailing, "Minimum quality required to keep a trailing base", :default => 15, :type => Integer
  opt :windowsize, "Size of sliding window across which to average quality", :default => 4, :type => Integer
  opt :quality, "Quality cutoff to use in sliding window trimming", :default => 15, :type => Integer
  opt :minlen, "Minimum length of reads (any shorter than this after trimming are discarded)", :default => 60, :type => Integer
  opt :cleanup, "Remove input files after they are processed"
end

t0 = Time.now

pairedlist, singlelist = [], []

# check inputs
if (opts.pairedfile && opts.paired) || (opts.singlefile && opts.single)
  abort "Choose either file or list input but not both"
end

# check list file and load if OK
def check_list_file(file, outlist)
  unless File.exists?(file)
    raise "Can't find file \"#{opts.input}\""
  end
  File.open(file, "r").each_line do |line|
    unless line.nil?
      outlist << line.chomp
    end
  end
end

check_list_file(opts.pairedfile, pairedlist) if opts.pairedfile
check_list_file(opts.singlefile, singlelist) if opts.singlefile

# check list and load if OK
def check_list(inlist, outlist)
  outlist += inlist.split(":")
  outlist.map! { |file|  File.expand_path(file)}
  outlist.each do |file|
    unless File.exists?(file)
      raise "Can't find file \"#{file}\""
    end
  end
end

check_list(opts.paired, pairedlist) if opts.paired
check_list(opts.single, singlelist) if opts.single

# build command(s)
pairedcmd, singlecmd = nil, nil

if opts.paired || opts.pairedfile
  pairedcmd = "java -jar #{opts.jar} PE -phred33 INFILEF INFILER OUTFILEF OUTFILER"
  pairedcmd += " ILLUMINACLIP:#{opts.adapters}:2:40:15" if opts.adapters
  pairedcmd += " LEADING:#{opts.leading} TRAILING:#{opts.trailing} SLIDINGWINDOW:#{opts.windowsize}:#{opts.quality} MINLEN:#{opts.minlen}"
end

if opts.single || opts.single
  singlecmd = "java -jar #{opts.jar} SE -phred33 INFILE OUTFILE"
  singlecmd += " ILLUMINACLIP:#{opts.adapters}:2:40:15" if opts.adapters
  singlecmd += " LEADING:#{opts.leading} TRAILING:#{opts.trailing} SLIDINGWINDOW:#{opts.windowsize}:#{opts.quality} MINLEN:#{opts.minlen}"
end

# trim
pairedlist.each_slice(2) do |infilef, infiler|
  cmd = pairedcmd
  cmd = cmd.gsub(/INFILEF/, infilef)
  cmd = cmd.gsub(/INFILER/, infiler)
  cmd = cmd.gsub(/OUTFILEF/, "#{TRIMPREFIX}#{infilef}")
  cmd = cmd.gsub(/OUTFILER/, "#{TRIMPREFIX}#{infiler}")
  puts "trimming #{infilef} and #{infiler}"
  puts cmd
  `#{cmd}`
  if opts.cleanup
    File.delete infilef
    File.delete infiler
  end
end

singlelist.each do |infile|
  cmd = singlecmd
  cmd = cmd.gsub(/INFILE/, infile)
  cmd = cmd.gsub(/OUTFILE/, "#{TRIMPREFIX}#{infile}")
  puts "trimming #{infile}"
  puts cmd
  `#{cmd}`
  File.delete infile if opts.cleanup
end

puts "Done! Trimmed #{pairedlist.length + singlelist.length} files in #{Time.now - t0} seconds"
