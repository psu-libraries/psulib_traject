# frozen_string_literal: true

require 'csv'
require 'config'

namespace :hathitrust do
  desc 'Process overlap file for emergency access to restricted HathiTrust material'
  task :process_hathi_overlap do
    Config.setup do |config|
      config.const_name = 'ConfigSettings'
      config.use_env = true
      config.load_and_set_settings(Config.setting_files('config', ENV['RUBY_ENVIRONMENT']))
    end

    period = ConfigSettings.hathi_load_period
    overlap_file = ConfigSettings.overlap_file

    Dir.chdir(ConfigSettings.hathi_overlap_path) do
      Rake::Task['hathitrust:load_hathi_full'].invoke(period)
      Rake::Task['hathitrust:pare_hathi_full'].invoke(period)
      Rake::Task['hathitrust:extract_multi_oclc'].invoke
      Rake::Task['hathitrust:split_multi_oclc'].invoke
      Rake::Task['hathitrust:merge_split_oclc'].invoke
      Rake::Task['hathitrust:extract_overlap_oclc'].invoke(overlap_file)
      Rake::Task['hathitrust:split_overlap_oclc'].invoke
      Rake::Task['hathitrust:filter_overlap'].invoke
    end
  end

  desc 'Download the monthly HathiTrust file from the HathiFiles page'
  task :load_hathi_full, [:period] do |_task, args|
    print `curl -s -O 'https://www.hathitrust.org/sites/www.hathitrust.org/files/hathifiles/hathi_full_#{args[:period]}.txt.gz'`
  end

  desc 'Pare the monthly file down to just the needed data: OCLC number, HathiTrust id, HathiTrust bib_key and HathiTurst access code'
  task :pare_hathi_full, [:period] do |_task, args|
    print `gunzip -c hathi_full_#{args[:period]}.txt.gz | \
               csvcut -t -c 8,1,4,2 -z 1310720 | \
               csvgrep -c 1,2,3,4 -r ".+" | \
               sort | uniq > hathi_all_dedupe.csv`

    print `{ echo "oclc_num,htid,ht_bib_key,access"; cat hathi_all_dedupe.csv; } > hathi_all_dedupe_with_headers.csv`
  end

  desc 'Extract lines with multiple oclc\'s'
  task :extract_multi_oclc do
    print `csvgrep -c 1 -r "," hathi_all_dedupe_with_headers.csv > hathi_multi_oclc.csv`
  end

  desc 'Split multiple oclc\'s'
  task :split_multi_oclc do
    data = []

    CSV.read('hathi_multi_oclc.csv', headers: true, header_converters: :symbol).each do |row|
      row[:oclc_num].split(',').each do |oclc|
        data << [oclc, row[:htid], row[:ht_bib_key], row[:access]]
      end
    end

    CSV.open('hathi_multi_oclc_split.csv', 'wb') do |csv|
      data.each do |row|
        csv << row
      end
    end
  end

  desc 'Merge splitted rows to deduped full file'
  task :merge_split_oclc do
    print `csvgrep -c 1 -r "," -i hathi_all_dedupe_with_headers.csv > hathi_single_oclc.csv`

    print `cat hathi_single_oclc.csv hathi_multi_oclc_split.csv > hathi_full_dedupe_with_headers.csv`
  end

  desc 'Extract the unique set of OCLC numbers and access code from the overlap report'
  task :extract_overlap_oclc, [:overlap_file] do |_task, args|
    print `csvgrep -t -c 4 -r ".+" #{args[:overlap_file]} | \
               csvcut -c 1,3 | \
               sort | uniq  > overlap_all_unique.csv`
  end

  desc 'Split the overlap report by item_type: mono and multi/serial'
  task :split_overlap_oclc do
    print `csvgrep -H -c 2 -m "mono" overlap_all_unique.csv | \
               csvcut -c 1 | \
               sort | uniq  > overlap_mono_unique.csv`

    print `csvgrep -H -c 2 -m "mono" -i overlap_all_unique.csv | \
               csvcut -c 1 | \
               sort | uniq  > overlap_multi_unique.csv`
  end

  desc 'Filter the pared down HathiTrust data using the overlap OCLC numbers as the filter input'
  task :filter_overlap do
    print `csvgrep -c 1 -f overlap_mono_unique.csv hathi_full_dedupe_with_headers.csv | \
               csvcut -C 3 | \
               sort | uniq > final_hathi_mono_overlap.csv`

    print `csvgrep -c 1 -f overlap_multi_unique.csv hathi_full_dedupe_with_headers.csv | \
               csvcut -C 2 | \
               sort | uniq > final_hathi_multi_overlap.csv`
  end
end
