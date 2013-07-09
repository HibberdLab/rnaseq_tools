#!/usr/bin/ruby

#
# khmer-batch
#
# Take in a set of fastq files and run khmer normalize-by-median.py on each
#   storing the hashtable at each step and using it for the next step
#
# Make sure normalize-by-median.py is in your PATH or specify the location
# with the --script option
#
# Chris Boursnell (cmb211@cam.ac.uk)
# created: 08/07/2013
# last modified: 08/07/2013
#

require 'rubygems'
require 'trollop'
require 'bio'

opts = Trollop::options do
  version "v0.0.1a"
  opt :input, "A file of fastq files, 1 per line", :type => String
  opt :files, "A list of colon separated input fastq files", :type => String
  opt :script, "Specify the location of the khmer normalize-by-median.py script if it is not in your PATH", :default => "normalize-by-median.py", :type => String
  opt :paired, "If the input fastq files are interleaved paired reads"
  opt :memory, "Maximum amount of memory to be used by khmer in gigabytes (default:4)", :default => 4.0, :type => :float
  opt :kmer, "K value to use in khmer (default:21)", :default => 21, :type => :int
  opt :buckets, "Number of buckets (default:4)", :default => 4, :type => :int
end

filelist=[]
# check inputs
if (opts.input and opts.files)
  abort "Choose either --input or --files but not both"
elsif opts.input
  if !File.exists?(opts.input)
    abort "Can't find file \"#{opts.input}\""
  end
  File.open(opts.files, "r").each_line do |line|
    filelist << line.chomp
  end
elsif opts.files
  filelist = opts.files.split(":")
  filelist.map! { |file|  File.expand_path(file)}
  filelist.each do |file|
    if !File.exists?(file)
      abort "Can't find file \"#{file}\""
    end
  end
end

# normalize-by-median.py -p -k 20 -N 12 -x 64e9 --savehash table.kh filename.fq
# normalize-by-median.py -p -k 20 -N 12 -x 64e9 --loadhash table.kh --savehash table2.kh filename2.fq

#For normalize-by-median, khmer uses one byte per hash entry, 
#  so: if you had 16 GB of available RAM, you should specify 
#  something like -N 4 -x 4e9, which multiplies out to about 16 GB.

puts "#{opts.memory}GB"

n = opts.buckets
x = (opts.memory/opts.buckets*1e9).to_i

#puts "Number of buckets to use is #{n}"
#puts "Size of each bucket is #{x.to_i}"

pair=""
if (opts.paired)
  pair = "-p"
end
first = true
filelist.each do |file|
  if first
    cmd = "#{opts.script} #{pair} -k #{opts.kmer} -N #{n} -x #{x} --savehash table.kh #{file}"
    `#{cmd}`
    first = false
  else
    cmd = "#{opts.script} -p -k #{opts.kmer} -N #{n} -x #{x} --load table.kh --savehash table2.kh #{file}"
    `#{cmd}`
    `mv table2.kh table.kh`
  end
end