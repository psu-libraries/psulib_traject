# frozen_string_literal: true

require 'rspec-sidekiq'
require 'sidekiq/testing'
require 'sidekiq/testing/inline'

Sidekiq::Testing.fake!

RSpec::Sidekiq.configure do |conf|
    # Clears all job queues before each example
    conf.clear_all_enqueued_jobs = true # default => true
    # Whether to use terminal colours when outputting messages
    conf.enable_terminal_colours = true # default => true
    # Warn when jobs are not enqueued to Redis but to a job array
    conf.warn_when_jobs_not_processed_by_sidekiq = false # default => true
end