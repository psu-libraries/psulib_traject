# frozen_string_literal: true

require 'solr_wrapper/rake_task'
require 'rsolr'

namespace :psulib_traject do
  namespace :solr do
    desc 'Updates .solr_wrapper.yml and solr config files from gitlab'
    task :update do
      solr_dir = "#{File.dirname(__FILE__)}/solr"
      solr_files = ['elevate.xml', 'mapping-ISOLatin1Accent.txt', 'protwords.txt', 'schema.xml',
                   'scripts.conf', 'solrconfig.xml', 'spellings.txt', 'stopwords.txt', 'stopwords_en.txt',
                   'synonyms.txt', 'admin-extra.html', '_rest_managed.json']

      solr_files.each do |file|
        response = Faraday.get url_for_file("solr/conf/#{file}")
        File.open(File.join(solr_dir, 'conf', file), 'wb') { |f| f.write(response.body) }
      end

      response = Faraday.get url_for_file(".solr_wrapper.yml")
      File.open("#{File.dirname(__FILE__)}/.solr_wrapper.yml", 'wb') { |f| f.write(response.body) }
    end

    def url_for_file(file)
      "https://raw.githubusercontent.com/psu-libraries/psulib_blacklight/master/#{file}"
    end
  end
end