# frozen_string_literal: true

require 'traject'
require './lib/psulib_traject/indexer'
require 'sidekiq'

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

  desc 'Index a file or folder of files async with sidekiq'
  task :index_async, [:path, :collection] do |_task, args|
    Dir[args.path].each do |f|
      IndexFileWorker.perform_async(f, args.collection)
    end
  end

  desc 'Index a file or folder of files without sidekiq'
  task :index, [:path] do |_task, args|
    traject_indexer.perform(args.path)
  end

  desc 'Run Hourlies'
  task :hourlies do |_task|
    HourliesWorker.new.perform
  end

  desc 'Clear redis of hourly semaphores'
  task :clear_hourlies do |_task|
    require 'redis'
    redis = Redis.new
    redis.keys('hr:*').map { |e| redis.del(e) }
  end
end
