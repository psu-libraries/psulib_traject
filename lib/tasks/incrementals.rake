# frozen_string_literal: true

require 'traject'

SIRSI_DATA_HOME = '/data/symphony_data'

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
    require 'config'
    Config.setup do |config|
      config.const_name = 'ConfigSettings'
      config.use_env = true
      config.load_and_set_settings(Config.setting_files('config', ENV['RUBY_ENVIRONMENT']))
    end

    indexer = Traject::Indexer.new(
      'solr.url': ConfigSettings.solr.url,
      'log.batch_size': ConfigSettings.log.batch_size,
      'solr.version': ConfigSettings.solr.version,
      'log.file': ConfigSettings.log.file,
      'log.error_file': ConfigSettings.log.error_file,
      'solr_writer.commit_on_close': ConfigSettings.solr_writer.commit_on_close,
      'reader_class_name': ConfigSettings.reader_class_name,
      'commit_timeout': ConfigSettings.commit_timeout,
      'hathi_overlap_path': ConfigSettings.hathi_overlap_path,
      'hathi_etas': ConfigSettings.hathi_etas,
      'marc4j_reader.permissive': ConfigSettings.marc4j_reader.permissive,
      'marc4j_reader.source_encoding': ConfigSettings.marc4j_reader.source_encoding,
      'processing_thread_pool': ConfigSettings.processing_thread_pool
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
