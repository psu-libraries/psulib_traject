# frozen_string_literal: true

require 'mail'

TRAJECT_HOME = '/opt/psulib_traject'.freeze
TRAJECT_LOGS_HOME = '/var/log/traject'.freeze
SIRSI_DATA_HOME = '/data/symphony_data'.freeze

# This job, and :delete_daily expect there to be file to add and delete, it is not responsible for getting those files
# from the catalog.
namespace :incrementals do
  desc 'Adds to the index'
  task :import_daily do
    daily_addition_files = Dir["#{SIRSI_DATA_HOME}/daily/*.mrc"]

    daily_addition_files.each do |f|
      system("bundle exec traject -s log.file=#{TRAJECT_LOGS_HOME}/traject_incremental.log -s "\
             "log.error_file=#{TRAJECT_LOGS_HOME}/traject_incremental_error.log -s processing_thread_pool=7 "\
             "-c #{TRAJECT_HOME}/lib/traject/psulib_config.rb #{f}")
      if $CHILD_STATUS.exitstatus.zero?
        File.delete(f)
      else
        Mail.deliver do
          from    'noreply@psu.edu'
          to      'cdm32@psu.edu'
          subject 'The daily import to BlackCat failed'
          body    "Traject failed to import the marc file #{f}."
        end
      end
    end
  end

  desc 'Deletes from the index'
  task :delete_daily do
    require 'traject'
    require 'yaml'
    indexer_settings = YAML.load_file('config/indexer_settings.yml')

    indexer = Traject::Indexer.new(
      'solr.version' => indexer_settings['solr_version'],
      'solr.url' => indexer_settings['solr_url'],
      'log.file' => "#{TRAJECT_LOGS_HOME}/traject_incremental.log",
      'log.error_file' => "#{TRAJECT_LOGS_HOME}/traject_incremental_error.log",
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
          id = line.chomp.chomp('|')
          indexer.writer.delete(id)
          response = HTTP.get "#{indexer_settings['solr_url']}/select?defType=edismax&fq=id:#{id}"
          parsed_response = JSON.parse(response)

          # Sanity checking, may be uneccesary bloat because the SolrJsonWrite::delete will throw an exception if the
          # response from the server isn't 200, and that only happens when the delete fails (as far as I know).
          if parsed_response['response']['numFound'] != 0
            didnt_work << id
            dont_delete << file_name
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
end
