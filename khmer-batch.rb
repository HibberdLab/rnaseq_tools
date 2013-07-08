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
    puts file
    if !File.exists?(file)
      abort "Can't find file \"#{file}\""
    else
      puts "Found \"#{file}\""
    end
  end
end
