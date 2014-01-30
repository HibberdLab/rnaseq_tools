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

class String
  def revcomp
    self.tr("ACGT", "TGCA").reverse
  end
end

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
    @start = a[3].to_i
    @stop = a[4].to_i
    @id = name
    @strand = a[6]
  end

  def to_s
    "#{@chromosome}\t#{@type}\t#{@start}..#{@stop}\t#{@strand}\t#{@id}"
  end
end

genome_hash = Hash.new
count=0
genome = Bio::FastaFormat.open(opts.genome)
genome.each do |entry|
  genome_hash[entry.entry_id] = entry.seq
end

hash = Hash.new

File.open("#{opts.annotation}", "r").each_line do |line|
  line.chomp!
  if line !~ /mRNA/
    g = Gff.new(line)
    if !hash.has_key?(g.id)
      hash[g.id]=[]
    end
    hash[g.id] << g
  end
end

hash.each_pair do |id, list|
  if list[0].strand == "+"
    list.sort! { |x,y| x.start <=> y.start }
    seq=""
    if genome_hash.has_key?(list[0].chromosome)
      list.each do |i|
        s = genome_hash[i.chromosome]
        # puts "substring #{i.start} to #{i.stop} of string length #{s.length}"
        seq << s[i.start..i.stop]
      end
    else
      abort "oh dear I appear to have a problem finding #{list[0].chromosome}"
    end
    puts ">#{list[0].id}"
    puts seq
  else # strand == "-"
    list.sort! { |x,y| y.stop <=> x.stop }
    seq=""
    if genome_hash.has_key?(list[0].chromosome)
      list.each do |i|
        s = genome_hash[i.chromosome]
        seq << s[i.start..i.stop]
      end
    else
      abort "oh dear I appear to have a problem finding #{list[0].chromosome}"
    end
    puts ">#{list[0].id}"
    puts seq.revcomp
  end
end