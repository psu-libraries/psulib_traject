# frozen_string_literal: true

$LOAD_PATH.prepend(Pathname.pwd.join('lib').to_s)

ENV['RUBY_ENVIRONMENT'] ||= 'dev'

require 'pry' if /dev|test/.match?(ENV['RUBY_ENVIRONMENT'])
require 'bundler/setup'
require 'psulib_traject'

extend Traject::Macros::Marc21
extend Traject::Macros::Marc21Semantics
extend PsulibTraject::Macros

Config.setup do |config|
  config.const_name = 'ConfigSettings'
  config.use_env = true
  config.load_and_set_settings(Config.setting_files('config', ENV['RUBY_ENVIRONMENT']))
end

settings do
  provide 'solr.url', "#{ConfigSettings.solr.url}#{ConfigSettings.solr.collection_name}"
  provide 'log.batch_size', ConfigSettings.log.batch_size
  provide 'solr.version', ConfigSettings.solr.version
  provide 'log.file', ConfigSettings.log.file
  provide 'log.error_file', ConfigSettings.log.error_file
  provide 'solr_writer.commit_on_close', ConfigSettings.solr_writer.commit_on_close
  provide 'reader_class_name', ConfigSettings.reader_class_name
  provide 'commit_timeout', ConfigSettings.commit_timeout
  provide 'hathi_overlap_path', ConfigSettings.hathi_overlap_path

  if RUBY_ENGINE == 'jruby'
    provide 'marc4j_reader.permissive', ConfigSettings.marc4j_reader.permissive
    provide 'marc4j_reader.source_encoding', ConfigSettings.marc4j_reader.source_encoding
    provide 'processing_thread_pool', ConfigSettings.processing_thread_pool
  end
end
ATOZ = ('a'..'z').to_a.join('')
ATOU = ('a'..'u').to_a.join('')

logger.info RUBY_DESCRIPTION

# Identifiers
#
## Catkey
to_field 'id', extract_marc('001'), first_only, strip

# Title fields
#
## Title Search Fields
to_field 'title_245ab_tsim', extract_marc('245ab'), trim_punctuation

## Access facet
access_facet_processor = PsulibTraject::Processors::AccessFacet.new
to_field 'access_facet' do |record, accumulator, context|
  access_facet = access_facet_processor.extract_access_data record, context
  accumulator.replace(access_facet) unless !access_facet || access_facet.empty?
end

to_field 'call_number_raw', extract_marc('949aw', separator: ', scheme: ')

to_field 'call_number_base' do |record, accumulator, context|
  call_number_base = PsulibTraject::Holdings.call(record: record, context: context)
  accumulator.replace(call_number_base) unless !call_number_base || call_number_base.empty?
end
