# frozen_string_literal: true

require 'traject'

SIRSI_DATA_HOME = '/data/symphony_data'.freeze

# This job, and :delete_daily expect there to be file to add and delete, it is not responsible for getting those files
# from the catalog.
namespace :incrementals do
  desc 'Adds to the index'
  task :import, [:period] do |_task, args|
    require 'mail'
    indexer = Traject::Indexer::MarcIndexer.new
    indexer.load_config_file('lib/traject/psulib_config.rb')
    target = Dir["#{SIRSI_DATA_HOME}/#{args[:period]}_#{ENV['RUBY_ENVIRONMENT']}/*.mrc"]
    indexer.logger.info "   Processing incremental import_#{args[:period]} rake task on #{target}"
    array_of_files = target.collect { |file| File.new(file) }

    if indexer.process array_of_files
      indexer.logger.info "   #{target} has been indexed"
      target.each { |file_name| File.delete file_name }
    else
      # This is here mostly as a test.
      Mail.deliver do
        from    'noreply@psu.edu'
        to      'cdm32@psu.edu,bzk60@psu.edu'
        subject 'The daily import to BlackCat failed'
        body    "Traject failed to import the marc file #{file_name}."
      end
    end
  end

  desc 'Deletes from the index'
  task :delete, [:period] do |_task, args|
    require 'yaml'
    indexer_settings = YAML.load_file("config/indexer_settings_#{ENV['RUBY_ENVIRONMENT']}.yml")
    SOLR_URL = ENV['RUBY_ENVIRONMENT'] == 'production' ? ENV['SOLR_URL'] : indexer_settings['solr_url']

    indexer = Traject::Indexer.new(
      'solr.version' => indexer_settings['solr_version'],
      'solr.url' => SOLR_URL,
      'log.file' => indexer_settings['log_file'],
      'log.error_file' => indexer_settings['log_error_file'],
      'solr_writer.commit_on_close' => indexer_settings['solr_writer_commit_on_close'],
      'marc4j_reader.permissive' => indexer_settings['marc4j_reader_permissive'],
      'marc4j_reader.source_encoding' => indexer_settings['marc4j_reader_source_encoding'],
      'processing_thread_pool' => indexer_settings['processing_thread_pool'].to_i
    )

    Dir["#{SIRSI_DATA_HOME}/#{args[:period]}_#{ENV['RUBY_ENVIRONMENT']}/*.txt"].each do |file_name|
      File.open(file_name, 'r') do |file|
        file.each_line do |line|
          id = line.chomp
          indexer.writer.delete(id)
          indexer.logger.info "   Deleted #{id} as part of incremental delete_#{args[:period]} rake task"
        end

        File.delete(file)
      end
    end
  end
end
