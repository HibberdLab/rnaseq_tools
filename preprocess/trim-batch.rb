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
require 'csv'

TRIMPREFIX = 't.'
UNPAIREDPREFIX = 'u.'

opts = Trollop::options do
  version "v0.0.1a"
  banner <<-EOS
trim-batch: run trimmomatic on multiple fastq files.

Single-end and/or paired-end can be included.
Trimmed files are outputted as '#{TRIMPREFIX}<input filename>'.
Paired reads whose pair is discarded are outputted as '#{TRIMPREFIX}#{UNPAIREDPREFIX}<input filename>'.
Log will be printed to <data><time>.trim.csv

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
  p inlist, outlist
  outlist += inlist.split(":")
  p outlist
  outlist.map! { |file|  File.expand_path(file) }
  outlist.each do |file|
    unless File.exists?(file)
      raise "Can't find file \"#{file}\""
    end
  end
end

check_list(opts.paired, pairedlist) if opts.paired
check_list(opts.single, singlelist) if opts.single

p singlelist

# build command(s)
pairedcmd, singlecmd = nil, nil

if opts.paired || opts.pairedfile
  pairedcmd = "java -jar #{opts.jar} PE -phred33 INFILEF INFILER OUTFILEF OUTFILEFU OUTFILER OUTFILERU"
  pairedcmd += " ILLUMINACLIP:#{opts.adapters}:2:40:15" if opts.adapters
  pairedcmd += " LEADING:#{opts.leading} TRAILING:#{opts.trailing} SLIDINGWINDOW:#{opts.windowsize}:#{opts.quality} MINLEN:#{opts.minlen}"
end

if opts.single || opts.singlefile
  singlecmd = "java -jar #{opts.jar} SE -phred33 INFILE OUTFILE"
  singlecmd += " ILLUMINACLIP:#{opts.adapters}:2:40:15" if opts.adapters
  singlecmd += " LEADING:#{opts.leading} TRAILING:#{opts.trailing} SLIDINGWINDOW:#{opts.windowsize}:#{opts.quality} MINLEN:#{opts.minlen}"
end

paired_trimlog = []
unpaired_trimlog = []

# trim
pairedlist.each_slice(2) do |infilef, infiler|
  cmd = pairedcmd
  cmd = cmd.gsub(/INFILEF/, infilef)
  cmd = cmd.gsub(/INFILER/, infiler)
  inpathf = File.dirname(infilef)
  infilef = File.basename(infilef)
  inpathr = File.dirname(infiler)
  infiler = File.basename(infiler)
  cmd = cmd.gsub(/OUTFILEF/, "#{inpathf}/#{TRIMPREFIX}#{infilef}")
  cmd = cmd.gsub(/OUTFILEFU/, "#{inpathf}/#{TRIMPREFIX}#{UNPAIREDPREFIX}#{infilef}")
  cmd = cmd.gsub(/OUTFILER/, "#{inpathr}/#{TRIMPREFIX}#{infiler}")
  cmd = cmd.gsub(/OUTFILERU/, "#{inpathr}/#{TRIMPREFIX}#{UNPAIREDPREFIX}#{infiler}")
  puts "trimming #{infilef} and #{infiler}"
  ret = `#{cmd} 2>&1`
  ret.split('\n').each do |line|
    next unless line =~ /^Input/
    data = /Input Read Pairs: (?<input_reads>\d+) Both Surviving: (?<both_kept>\d+) \((?<both_kept_pc>[^\)]+)\) Forward Only Surviving: (?<fwd_kept>\d+) \((?<fwd_kept_pc>[^\)]+)\) Reverse Only Surviving: (?<rev_kept>\d+) \((?<rev_kept_pc>[^\)]+)\) Dropped: (?<dropped>\d+) \((?<dropped_pc>[^\)]+)\)/.match(line)
    logline = Hash[data.names.zip(data.captures)]
    logline['file'] = infilef
    paired_trimlog << logline
  end
  if opts.cleanup
    File.delete infilef
    File.delete infiler
  end
end

singlelist.each do |infile|
  cmd = singlecmd
  cmd = cmd.gsub(/INFILE/, infile)
  inpath = File.dirname(infile)
  infile = File.basename(infile)
  cmd = cmd.gsub(/OUTFILE/, "#{inpath}/#{TRIMPREFIX}#{infile}")
  puts "trimming #{infile}"
  ret = `#{cmd} 2>&1`
  p ret
  ret.split(/\n/).each do |line|
    p line
    next unless line =~ /^Input/
    data = /Input Reads: (?<input_reads>\d+) Surviving: (?<kept>\d+) \((?<kept_pc>[^\)]+)\) Dropped: (?<dropped>\d+) \((?<dropped_pc>[^\)]+)\)/.match(line)
    logline = Hash[data.names.zip(data.captures)]
    logline['file'] = infile
    unpaired_trimlog << logline
  end
  # File.delete infile if opts.cleanup
end

datestr = Time.now.strftime('%d_%m_%Y_%H_%M_%S')
protfile = "#{datestr}.trim.protocol"
puts "Saving protocol to #{protfile}"
File.open(protfile, 'w') do |protocol|
  protocol.puts opts
end

logsuffix = "#{datestr}.trim.csv"
def writelog(logarr, logfile)
  return if logarr.length == 0
  header = logarr.first.keys
  CSV.open(logfile, 'w') do |log|
    log << header
    logarr.each do |line|
      log << header.map { |h| line[h] }
    end
  end
end

writelog(paired_trimlog, "paired.#{logsuffix}")
writelog(unpaired_trimlog, "unpaired.#{logsuffix}")
  
puts "Done! Trimmed #{pairedlist.length + singlelist.length} files in #{Time.now - t0} seconds"
