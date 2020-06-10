# frozen_string_literal: true

namespace :hathitrust do
  desc 'Process overlap file for emergency access to restricted HathiTrust material'
  task :process_hathi_overlap do
    indexer_settings = YAML.load_file("config/indexer_settings_#{ENV['RUBY_ENVIRONMENT']}.yml")
    period = indexer_settings['hathi_load_period']

    Dir.chdir(indexer_settings['hathi_overlap_path']) do
      Rake::Task['hathitrust:load_hathi_full'].invoke(period)
      Rake::Task['hathitrust:pare_hathi_full'].invoke(period)
      Rake::Task['hathitrust:extract_overlap_oclc'].invoke(indexer_settings['overlap_file'])
      Rake::Task['hathitrust:split_overlap_oclc'].invoke
      Rake::Task['hathitrust:filter_overlap'].invoke
      # Rake::Task['hathitrust:extract_uniq_oclc'].invoke
    end
  end

  desc 'Download the monthly HathiTrust file from the HathiFiles page'
  task :load_hathi_full, [:period] do |_task, args|
    print `curl -s -O 'https://www.hathitrust.org/sites/www.hathitrust.org/files/hathifiles/hathi_full_#{args[:period]}.txt.gz'`
  end

  desc 'Pare the monthly file down to just the needed data: OCLC number, Hathi Trust id, Hathi Trust bib_key and Hathi Turst access code'
  task :pare_hathi_full, [:period] do |_task, args|
    print `gunzip -c hathi_full_#{args[:period]}.txt.gz | \
               csvcut -t -c 8,1,4,2 -z 1310720 | \
               csvgrep -c 1,2,3,4 -r ".+" | \
               sort | uniq > hathi_full_dedupe.csv`

    print `cat hathi_field_list.txt hathi_full_dedupe.csv > hathi_full_dedupe_with_headers.csv`
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
               sort | uniq > hathi_filtered_by_mono_overlap.csv`

    print `csvgrep -c 1 -f overlap_multi_unique.csv hathi_full_dedupe_with_headers.csv | \
               csvcut -C 2 | \
               sort | uniq > hathi_filtered_by_multi_overlap.csv`
  end

  desc 'Extract the unique set of OCLC numbers from the filtered data'
  task :extract_uniq_oclc do
    print `sort -t, -k2 -u hathi_filtered_by_overlap.csv > final_hathi_overlap.csv`
  end
end
