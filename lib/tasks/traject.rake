# frozen_string_literal: true

namespace :traject do
  desc 'Index a file or folder of files'
  task :index, [:path] do |_task, args|
    PsulibTraject::Workers::Indexer.perform_now(args.path, args.collection)
  end

  desc 'Run Incrementals'
  task :Incrementals do 
    PsulibTraject::Workers::IncrementalsIndexer.perform_now
  end

  desc 'Run Hourlies'
  task :hourlies do
    PsulibTraject::Workers::HourlyIndexer.perform_now
  end

  desc 'Clear redis of hourly semaphores'
  task :clear_hourlies do
    redis = Redis.new
    redis.keys('hr:*').map { |key| redis.del(key) }
  end
end
