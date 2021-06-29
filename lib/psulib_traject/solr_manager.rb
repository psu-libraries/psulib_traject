# frozen_string_literal: true

require 'config'
require 'faraday'

module PsulibTraject
  # For interacting with Apache Solr, an incomplete implementation of
  # https://github.com/psu-libraries/psulib_blacklight/blob/master/lib/psulib_blacklight/solr_manager.rb
  class SolrManager
    COLLECTION_PATH = '/solr/admin/collections'

    def initialize
      Config.setup do |config|
        config.const_name = 'ConfigSettings'
        config.use_env = true
        config.env_prefix = 'SETTINGS'
        config.env_separator = '__'
        config.load_and_set_settings(Config.setting_files('config', ENV['RUBY_ENVIRONMENT']))
      end
    end

    def last_incremented_collection
      collections_with_prefix.max_by(&:version_number)
    end

    private

      def collections_with_prefix
        collections.select { |c| c.name.scan(/#{ConfigSettings.solr.collection}/) }
      end

      def collections
        resp = connection.get(COLLECTION_PATH, action: 'LIST')
        JSON.parse(resp.body)['collections'].map { |collection| SolrCollection.new(collection) }
      end

      def connection
        @connection ||= Faraday.new(url) do |faraday|
          faraday.request :basic_auth, ConfigSettings.solr.username, ConfigSettings.solr.password \
            if ConfigSettings.solr.username && ConfigSettings.solr.password
          faraday.request :multipart
          faraday.adapter :net_http
        end
      end

      def url
        "#{ConfigSettings.solr.protocol}://#{ConfigSettings.solr.host}:#{ConfigSettings.solr.port}/solr"
      end
  end

  # Lightweight Solr collection abstraction
  class SolrCollection
    def initialize(name)
      @name = name
    end

    attr_reader :name

    def to_s
      name
    end

    def version_number
      @name.scan(/\d+/).first.to_i
    end
  end
end
