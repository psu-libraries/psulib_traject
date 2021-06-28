# frozen_string_literal: true

require 'traject'
require './lib/psulib_traject/indexer'

namespace :traject do

    require 'config'
    Config.setup do |config|
      config.const_name = 'ConfigSettings'
      config.use_env = true
      config.env_prefix = 'SETTINGS'
      config.env_separator = '__'
      config.load_and_set_settings(Config.setting_files('config', ENV['RUBY_ENVIRONMENT']))
    end

  traject_indexer = IndexFileWorker.new
  solr_manager = PsulibTraject::SolrManager.new

  desc 'Index a file or folder of files async'
  task :index_async, [:path] do |_task, args|
    Dir[args.path].each do |f|
      IndexFileWorker.perform_async(filename=f)
    end
  end

  desc 'Index a file or folder of files'
  task :index, [:path] do |_task, args|
    traject_indexer.perform(filename=args.path)
  end

end