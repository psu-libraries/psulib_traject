# frozen_string_literal: true

require 'config'
require 'csv'
require 'library_stdnums'
require 'redis'
require 'sidekiq'
require 'sidekiq-scheduler'
require 'traject'
require 'traject/macros/marc21_semantics'
require 'yaml'

module PsulibTraject
  require 'psulib_traject/hathi_overlap_reducer'
  require 'psulib_traject/indexer'
  require 'psulib_traject/index_file_worker'
  require 'psulib_traject/index_worker'
  require 'psulib_traject/hourlies_worker'
  require 'psulib_traject/macros'
  require 'psulib_traject/marc_combining_reader'
  require 'psulib_traject/processors/access_facet'
  require 'psulib_traject/processors/format'
  require 'psulib_traject/processors/media_type'
  require 'psulib_traject/processors/preferred_format'
  require 'psulib_traject/processors/pub_date'
  require 'psulib_traject/processors/record_type'
  require 'psulib_traject/solr_manager'

  class << self
    # work-around for https://github.com/jruby/jruby/issues/4868
    def regex_to_extract_data_from_a_string(str, regex)
      str[regex]
    end
  end
end
