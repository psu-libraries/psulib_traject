# frozen_string_literal: true

module PsulibTraject
  class IndexWorker < Worker
    def perform(filename = nil, collection_name = nil)
      target = Dir[filename]
      target.each do |f|
        PsulibTraject::IndexFileWorker.perform_async(f, collection_name)
      end
    end
  end
end
