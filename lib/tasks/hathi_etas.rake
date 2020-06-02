# frozen_string_literal: true

HATHI_DATA_HOME = '/data/hathitrust_data'

namespace :hathitrust do
  desc 'Process overlap file for emergency access to restricted HathiTrust material'
  task :process_hathi_etas, [:hathi_full, :overlap_psu] do |_task, args|
    Dir.chdir(HATHI_DATA_HOME.to_s) do
      Rake::Task['hathitrust:pare_hathi_full'].invoke(args[:hathi_full])
      Rake::Task['hathitrust:extract_overlap_oclc'].invoke(args[:overlap_psu])
      Rake::Task['hathitrust:filter_overlap'].invoke
      Rake::Task['hathitrust:extract_uniq_oclc'].invoke
    end
  end

  desc 'Pare the monthly file down to just the needed data: Hathi Trust id and OCLC number'
  task :pare_hathi_full, [:hathi_full] do |_task, args|
    print `gunzip -c #{args[:hathi_full]} | \
               csvcut -t -c 1,8 -z 1310720 | \
               csvgrep -c 1,2 -r ".+" | \
               sort | uniq > hathi_full_dedupe.csv`
  end

  desc 'Extract the unique set of OCLC numbers from the overlap report'
  task :extract_overlap_oclc, [:overlap_psu] do |_task, args|
    print `csvgrep -t -c 4 -r ".+" #{args[:overlap_psu]} | \
               csvcut -c 1 | \
               sort | uniq  > overlap_all_unique.csv`
  end

  desc 'Filter the pared down HathiTrust data using the overlap OCLC numbers as the filter input'
  task :filter_overlap do
    print `csvgrep -c 2 -f overlap_all_unique.csv \
               hathi_full_dedupe.csv > hathi_filtered_by_overlap.csv`
  end

  desc 'Extract the unique set of OCLC numbers from the filtered data'
  task :extract_uniq_oclc do
    print `sort -t, -k2 -u hathi_filtered_by_overlap.csv > final_hathi_overlap.csv`
  end
end
