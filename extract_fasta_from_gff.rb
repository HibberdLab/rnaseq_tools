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
  opt :output, "Output file (defaults to stdout)", :type => String
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
    @start = a[3].to_i - 1
    @stop = a[4].to_i - 1
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

out = File.open("#{opts.output}", "w") if opts.output

hash.each_pair do |id, list|
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
  fasta = ">#{list[0].id}\n"
  if list[0].strand == "+"
    fasta << "#{seq}\n"
  else # strand == "-"
    fasta << "#{seq.revcomp}\n"
  end
  if opts.output
    out.write(fasta)
  else
    puts fasta
  end

end