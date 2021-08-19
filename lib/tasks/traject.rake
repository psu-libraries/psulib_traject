# frozen_string_literal: true

namespace :traject do
  desc 'Index a file or folder of files async with sidekiq'
  task :index_async, [:path, :collection] do |_task, args|
    target = Dir.glob("#{args.path}/**/*.m*rc")
    target.each do |file_name|
        puts "indexing #{file_name}"
        PsulibTraject::Workers::Indexer.perform_async(file_name, args.collection)
    end
  end

  desc 'Index a file or folder of files without sidekiq'
  task :index, [:path] do |_task, args|
    PsulibTraject::Workers::Indexer.perform_now(args.path, args.collection)
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
