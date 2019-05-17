# frozen_string_literal: true

require 'traject'

SIRSI_DATA_HOME = '/data/symphony_data'.freeze

# This job, and :delete_daily expect there to be file to add and delete, it is not responsible for getting those files
# from the catalog.
namespace :incrementals do
  desc 'Adds to the index'
  task :import, [:period] do |_task, args|
    require 'mail'
    today_ymd = Date.today.strftime('%Y%m%d')
    indexer = Traject::Indexer::MarcIndexer.new
    indexer.load_config_file('lib/traject/psulib_config.rb')
    file = "#{SIRSI_DATA_HOME}/#{args[:period]}_#{ENV['RUBY_ENVIRONMENT']}/#{args[:period]}_addupdate_#{today_ymd}.mrc"
    indexer.logger.info "   Processing incremental import_#{args[:period]} rake task on #{file}"

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
  task :delete, [:period] do |_task, args|
    require 'yaml'
    indexer_settings = if ENV['RUBY_ENVIRONMENT'] == 'production'
                         YAML.load_file('config/indexer_settings_production.yml')
                       else
                         YAML.load_file('config/indexer_settings.yml')
                       end

    indexer = Traject::Indexer.new(
      'solr.version' => indexer_settings['solr_version'],
      'solr.url' => indexer_settings['solr_url'],
      'log.file' => indexer_settings['log_file'],
      'log.error_file' => indexer_settings['log_error_file'],
      'solr_writer.commit_on_close' => indexer_settings['solr_writer_commit_on_close'],
      'marc4j_reader.permissive' => indexer_settings['marc4j_reader_permissive'],
      'marc4j_reader.source_encoding' => indexer_settings['marc4j_reader_source_encoding']
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
