# frozen_string_literal: true

require 'mail'
require 'traject'

SIRSI_DATA_HOME = '/data/symphony_data'.freeze

# This job, and :delete_daily expect there to be file to add and delete, it is not responsible for getting those files
# from the catalog.
namespace :incrementals do
  desc 'Adds to the index'
  task :import_daily do
    today_ymd = Date.today.strftime('%Y%m%d')
    file  = "#{SIRSI_DATA_HOME}/daily/daily_addupdate_#{today_ymd}.mrc"
    indexer = Traject::Indexer::MarcIndexer.new
    indexer.load_config_file('lib/traject/psulib_config.rb')
    indexer.logger.info "   Processing incremental import_daily rake task on #{f}"

    if indexer.process(File.open(file))
      indexer.logger.info "   #{file} has been indexed"
      File.delete file
    else
      Mail.deliver do
        from    'noreply@psu.edu'
        to      'cdm32@psu.edu'
        subject 'The daily import to BlackCat failed'
        body    "Traject failed to import the marc file #{file}."
      end
    end
  end

  desc 'Deletes from the index'
  task :delete_daily do
    require 'yaml'
    indexer_settings = YAML.load_file('config/indexer_settings.yml')

    indexer = Traject::Indexer.new(
      'solr.version' => indexer_settings['solr_version'],
      'solr.url' => indexer_settings['solr_url'],
      'log.file' => indexer_settingsp['log_file'],
      'log.error_file' => indexer_settings['log_error_file'],
      'solr_writer.commit_on_close' => indexer_settings['solr_writer_commit_on_close'],
      'marc4j_reader.permissive' => indexer_settings['marc4j_reader_permissive'],
      'marc4j_reader.source_encoding' => indexer_settings['marc4j_reader_source_encoding']
    )

    didnt_work = []
    daily_deletion_files = Dir["#{SIRSI_DATA_HOME}/daily/*.txt"]
    dont_delete = []

    daily_deletion_files.each do |file_name|
      File.open(file_name, 'r') do |file|
        file.each_line do |line|
          id = line.chomp
          if indexer.writer.delete(id)
            indexer.logger.info "   Deleted #{id} as part of incremental delete_daily rake task"
          else
            didnt_work << id
            dont_delete << file_name
          end
        end
      end
    end

    if didnt_work.any?
      Mail.deliver do
        from    'noreply@psu.edu'
        to      'cdm32@psu.edu'
        subject 'Some of the daily delete to BlackCat failed'
        body    "Solr failed to delete the following ids: #{didnt_work}"
      end
    end

    daily_deletion_files.each do |f|
      next unless dont_delete.include? f

      File.delete(f)
    end
  end
end
