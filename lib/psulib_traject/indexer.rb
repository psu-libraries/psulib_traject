# frozen_string_literal: true

require 'traject'
require 'sidekiq'
require 'sidekiq-scheduler'
require 'redis'

class HourliesWorker
  include Sidekiq::Worker

  require 'config'
  Config.setup do |config|
    config.const_name = 'ConfigSettings'
    config.use_env = true
    config.env_prefix = 'SETTINGS'
    config.env_separator = '__'
    config.load_and_set_settings(Config.setting_files('config', ENV['RUBY_ENVIRONMENT']))
  end

  def perform
    redis = Redis.new
    target = Dir.glob("#{ConfigSettings.symphony_data_path}/#{ConfigSettings.symphony_hourlies_subdir}/**/*.mrc")
    indexed_files = redis.keys('hr:*').map! { |e| e.gsub('hr:', '') }
    files_to_index = target - indexed_files

    files_to_index.each do |t|
      puts "indexing #{t}"
      ::IndexFileWorker.perform_async(t)
      redis.set("hr:#{t}", true)
    end
  end
end

class IndexerWorker
  include Sidekiq::Worker

  def perform(filename = nil, collection_name = nil)
    target = Dir[filename]
    target.each do |f|
      IndexFileWorker.perform_async(f, collection_name)
    end
  end
end

class IndexFileWorker
  include Sidekiq::Worker

  def perform(filename = nil, collection_name = nil)
    indexer = Traject::Indexer::MarcIndexer.new
    indexer.load_config_file('config/traject.rb')
    # if we are passed a collection name we index to it instead of what's in settings
    if collection_name
      url = indexer.settings['solr.url']
      indexer.settings['solr.url'] = url.gsub(url.split('/')[-1], collection_name)
    end

    target = Dir[filename]

    if target.empty?
      indexer.logger.info "#{target} is empty. nothing to index"
    else
      indexer.logger.info "Indexing #{target}"
      array_of_files = target.map { |file| File.new(file) }

      if indexer.process array_of_files
        indexer.logger.info "Indexed #{target}"
      end
    end
  end
end
