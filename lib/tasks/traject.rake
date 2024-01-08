# frozen_string_literal: true

namespace :traject do
  desc 'Index a file or folder of files'
  task :index, [:path] do |_task, args|
    PsulibTraject::Workers::Indexer.perform_now(args.path, args.collection)
  end

  desc 'Run Hourlies'
  task :hourlies do
    PsulibTraject::Workers::HourlyIndexer.perform_now
  end

  desc 'Clear redis of hourly skip list'
  task :clear_hourlies do
    current_collection = PsulibTraject::SolrManager.new.current_collection
    redis = Redis.new
    redis.keys("#{current_collection}:*").map { |key| redis.del(key) }
  end
end
