#!/usr/bin/env ruby

# script to collate FASTQC results for a 
# large number of samples, summarise the
# results and produce some plots of the summary data

require 'pp'
require 'zip/zipfilesystem'

species = ['Fp', 'Fr', 'Ft']
replicates = 3
numsamples = 6

def parse_fastqc_data(path)
  data = {}
  insection = false
  section = nil
  headers = nil
  Zip::ZipFile.open(path) do |zipfile|
    # fastqc archives contain an unrolled directory
    # we need to find it
    dir = zipfile.dir.entries('.').first
    # go in and get the fastqc_data
    zipfile.read("#{dir}/fastqc_data.txt").split(/\n/).each do |line|
      if line.start_with? '>>'
        # sections begin and end with '>>'-prefixed lines
        if insection && line == '>>END_MODULE'
          # section ended
          insection = false
          headers = nil
        else
          # new section
          section = line[2..-1].split(/\t/).first
          data[section] = {}
          insection = true
          headers = []
        end
      elsif insection
        if line.start_with? '#'
          # headers, create arrays
          if line.start_with? '#T'
            # one line doesn't follow the same spec
            # as the rest of the file. nice going,
            # fastqc devs ;)
            data[section]['Total Duplication Percentage'] = line.split(/\t/).last
            next
          end
          line[1..-1].split(/\t/).each do |header|
            data[section][header] = []
            headers << header
          end
        else
          # data, populate arrays
          line.split(/\t/).each_with_index do |datum, index|
            data[section][headers[index]] << datum
          end
        end
      else
        next
      end
    end
  end
  data
end


species.each do |sp|
  (1..replicates).each do |rep|
    (1..numsamples).each do |smpl|
      # Fp1_1.L001_CGATGTAT_001_fastqc_R1.zip
      fileglob = "#{sp}#{rep}_#{smpl}*fastqc*zip"
      Dir[fileglob].each do |filename|
        file = /([0-9])_fastqc_(R[0-9])/.match[1..2].join('_')
        pp filename
        pp parse_fastqc_data(filename)
        exit
      end
    end
  end
end
