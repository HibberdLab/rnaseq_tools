#!/usr/bin/env ruby


require 'rubygems'
require 'bio'
require 'trollop'


opts = Trollop::options do
  version "v0.0.1a"
  banner <<-EOS

extract_fasta_from_gff
Chris Boursnell (cmb211@cam.ac.uk)

EOS
  opt :genome, "Genome", :required => true, :type => String
  opt :annotation, "Gff file", :required => true, :type => String
  opt :verbose, "Be verbose"
end

Trollop::die :genome, "must exist" if !File.exist?(opts[:genome]) if opts[:genome]
Trollop::die :annotation, "must exist" if !File.exist?(opts[:annotation]) if opts[:annotation]

class Gff
  attr_accessor :chromosome, :type, :start, :stop, :id, :strand

  def initialize(line)
    a = line.split(/\t/)
    name="unknown"
    if a[8] =~ /.=(.*);/
      name = $1
    end
    @chromosome = a[0]
    @type = a[2]
    @start = a[3]
    @stop = a[4]
    @id = name
    @strand = a[6]
  end

  def to_s
    "#{@chromosome}\t#{@type}\t#{@start}..#{@stop}\t#{@strand}\t#{@id}"
  end
end

genome = Bio::FastaFormat.open(opt.genome)

hash = Hash.new

File.open("#{opt.annotation}", "r").each_line do |line|
  line.chomp!
  g = Gff.new(line)
  if !hash.has_key?(g.id)
    hash[g.id]=[]
  end
  hash[g.id] << g
end

