# frozen_string_literal: true

namespace :traject do
  desc 'Index a file or folder of files'
  task :index, [:path] do |_task, args|
    PsulibTraject::Workers::Indexer.perform_now(args.path, args.collection)
  end

  desc 'Run incrementals'
  task :incrementals do
    PsulibTraject::Workers::IncrementalIndexer.perform_now
  end

  desc 'Clear redis of incremental skip list'
  task :clear_incrementals do
    current_collection = PsulibTraject::SolrManager.new.current_collection
    redis = Redis.new
    redis.keys("#{current_collection}:*").map { |key| redis.del(key) }
  end
end
