# frozen_string_literal: true

require 'config'
require 'csv'
require 'faraday'
require 'library_stdnums'
require 'redis'
require 'shelvit'
require 'sidekiq'
require 'sidekiq-scheduler'
require 'traject'
require 'traject/macros/marc21_semantics'
require 'yaml'

module PsulibTraject
  require 'psulib_traject/call_number'
  require 'psulib_traject/hathi_overlap_reducer'
  require 'psulib_traject/holdings'
  require 'psulib_traject/macros'
  require 'psulib_traject/marc_combining_reader'
  require 'psulib_traject/null_object'
  require 'psulib_traject/processors/access_facet'
  require 'psulib_traject/processors/call_number/base'
  require 'psulib_traject/processors/call_number/dewey'
  require 'psulib_traject/processors/call_number/lc'
  require 'psulib_traject/processors/call_number/other'
  require 'psulib_traject/processors/format'
  require 'psulib_traject/processors/media_type'
  require 'psulib_traject/processors/preferred_format'
  require 'psulib_traject/processors/pub_date'
  require 'psulib_traject/processors/record_type'
  require 'psulib_traject/shelf_key'
  require 'psulib_traject/solr_manager'
  require 'psulib_traject/workers/base'
  require 'psulib_traject/workers/hourly_indexer'
  require 'psulib_traject/workers/indexer'

  Config.setup do |config|
    config.const_name = 'ConfigSettings'
    config.use_env = true
    config.env_prefix = 'SETTINGS'
    config.env_separator = '__'
    config.load_and_set_settings(Config.setting_files('config', ENV['RUBY_ENVIRONMENT']))
  end

  class << self
    # work-around for https://github.com/jruby/jruby/issues/4868
    def regex_to_extract_data_from_a_string(str, regex)
      str[regex]
    end
  end
end
