# frozen_string_literal: true

require 'traject'

# This job, and :delete_daily expect there to be file to add and delete, it is not responsible for getting those files
# from the catalog.
namespace :incrementals do
  desc 'Adds to the index'
  task :import, [:period] do |_task, args|
    indexer = Traject::Indexer::MarcIndexer.new
    indexer.logger.info 'name="Sirsi Incremental" '\
                        'message="Indexing operation beginning" '\
                        "task=\"#{args[:period]} import\" "\
                        'progress=start'
    indexer.load_config_file('lib/traject/psulib_config.rb')
    target = Dir["#{ConfigSettings.symphony_data_path}#{args[:period]}_#{ENV['RUBY_ENVIRONMENT']}/*.mrc"]

    if target.empty?
      indexer.logger.info 'name="Sirsi Incremental" '\
                          'message="Nothing to index" '\
                          "task=\"#{args[:period]} import\" "\
                          'progress=done'
    end

    indexer.logger.info 'name="Sirsi Incremental" '\
                        "message=\"Indexing #{target}\" "\
                        "task=\"#{args[:period]} import\" "\
                        'progress="in progress"'

    array_of_files = target.collect { |file| File.new(file) }

    if indexer.process array_of_files
      indexed_files = target.join ','
      indexer.logger.info 'name="Sirsi Incremental" '\
                          "message=\"Indexed #{indexed_files}\" "\
                          "task=\"#{args[:period]} import\" "\
                          'progress=done'
      target.each { |file_name| File.delete file_name }
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

    indexer.logger.info 'name="Sirsi Incremental" '\
                        'message="Deleting operation beginning" '\
                        "task=\"#{args[:period]} delete\" "\
                        'progress=start'

    ids = []

    Dir["#{ConfigSettings.symphony_data_path}#{args[:period]}_#{ENV['RUBY_ENVIRONMENT']}/*.txt"].each do |file_name|
      File.open(file_name, 'r') do |file|
        file.each_line do |line|
          id = line.chomp
          ids << id
          indexer.writer.delete(id)
        end

        File.delete(file)
      end
    end

    if ids.any?
      deleted_ids = ids.join ','
      indexer.logger.info 'name="Sirsi Incremental" '\
                          "message=\"Deleted #{deleted_ids}\" "\
                          "task=\"#{args[:period]} delete\" "\
                          'progress=done'
    else
      indexer.logger.info 'name="Sirsi Incremental" '\
                          'message="Nothing to delete" '\
                          "task=\"#{args[:period]} delete\" "\
                          'progress=done'
    end
  end
end
