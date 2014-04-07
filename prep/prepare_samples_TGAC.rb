#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# This script processes the raw sequence data download
# for next-generation sequencing from TGAC, collating
# files into samples and renaming them appropriately,
# and then saving a list of the collated files ready
# for downstream processing.
#
# The script should be run from inside the directory
# of the data download. This is the directory that
# contains the 'SampleAlias.txt' file.

samplefile = 'SampleAlias.txt'
samples = {}
if File.exist? samplefile
  l = 0
  File.open(samplefile).each do |line|
    l += 1
    next if l < 2
    line = line.strip.gsub(/\s+/, " ").split(" ")
    samples[line.first] = line[1]
  end
else
  raise "couldn't find the file SampleFiles.txt - did you run the script from the TGAC data dir?"
end

datadir = Dir['*'].delete_if{ |x| !File.directory?(x) }.first
files = []
Dir.chdir(datadir) do
  Dir['Sample*'].each do |sample|
    puts "moving into directory #{sample}"
    libid = sample.match(/(LIB[0-9]*)/).to_s
    sampleid = samples[libid]
    puts "library ID #{libid} corresponds to sample ID #{sampleid}"
    samplefile = "#{sampleid}.fastq.gz"
    puts "collating #{libid} files into #{samplefile}"
    Dir.chdir(sample) do
      `zcat *.fastq.gz | gzip > #{samplefile}` unless File.exist?(samplefile)
      files << File.join(Dir.pwd, samplefile)
    end
  end
end

listfile = "files_for_trimming.txt"
puts "writing file list for trimming to #{listfile}"
File.open(listfile, "w"){ |f| files.each{ |e| f.puts e } }
puts "done"
