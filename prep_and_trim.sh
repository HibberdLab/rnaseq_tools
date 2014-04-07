prepare_samples_TGAC.rb | tee sample_preparation.log
trim-batch.rb --singlefile files_for_trimming.txt \
--jar /home/rds45/apps/Trimmomatic-0.30/trimmomatic-0.30.jar \
--adapters /data/adapters/adapters_list.fa \
--cleanup | tee quality_adapter_trimming.log
