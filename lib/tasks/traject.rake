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

  traject_indexer = PsulibTraject::Indexer.new
  solr_manager = PsulibTraject::SolrManager.new

  desc 'Iterate Collection and Import'
  task :iterate_and_import do |_task|
    target = Dir["#{ConfigSettings.symphony_data_path}/full_extracts/*.mrc"]
  end

  desc 'Does a index of Data in symphony_data_path'
  task :full_extract do |_task|
    target = Dir["#{ConfigSettings.symphony_data_path}/full_extracts"]
    traject_indexer = PsulibTraject::Indexer.new
    target.each do |t|
      traject_indexer.perform(filename=t)
    end
  end

  desc 'Index a file or folder of files async'
  task :index_async, [:path] do |_task, args|
    Dir[args.path].each do |f|
      PsulibTraject::Indexer.perform_async(filename=f)
    end
  end

  desc 'Index a file or folder of files'
  task :index, [:path] do |_task, args|
    traject_indexer.perform(filename=args.path)
  end

  desc 'Imports sample data'
  task :sample do |_task|
    target = Dir["solr/sample_data/sample_psucat.mrc"]
    traject_indexer = PsulibTraject::Indexer.new
    target.each do |t|
      traject_indexer.perform(filename=t)
    end

  end
end