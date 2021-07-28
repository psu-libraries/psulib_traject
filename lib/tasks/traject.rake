# frozen_string_literal: true

namespace :traject do
  traject_indexer = PsulibTraject::IndexFileWorker.new

  desc 'Index a file or folder of files async with sidekiq'
  task :index_async, [:path, :collection] do |_task, args|
    Dir[args.path].each do |f|
      PsulibTraject::IndexFileWorker.perform_async(f, args.collection)
    end
  end

  desc 'Index a file or folder of files without sidekiq'
  task :index, [:path] do |_task, args|
    traject_indexer.perform(args.path)
  end

  desc 'Run Hourlies'
  task :hourlies do |_task|
    PsulibTraject::HourliesWorker.new.perform
  end

  desc 'Clear redis of hourly semaphores'
  task :clear_hourlies do |_task|
    require 'redis'
    redis = Redis.new
    redis.keys('hr:*').map { |e| redis.del(e) }
  end
end
