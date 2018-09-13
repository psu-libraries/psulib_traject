# frozen_string_literal: true

require 'solr_wrapper/rake_task'
require 'rsolr'

namespace :psulib_traject do
  namespace :solr do
    desc 'Updates solr config files from gitlab'
    task :update do
      solr_dir = "#{File.dirname(__FILE__)}/solr"

      ['elevate.xml', 'mapping-ISOLatin1Accent.txt', 'protwords.txt', 'schema.xml',
       'scripts.conf', 'solrconfig.xml', 'spellings.txt', 'stopwords.txt', 'stopwords_en.txt',
       'synonyms.txt', 'admin-extra.html', '_rest_managed.json'].each do |file|
        response = Faraday.get url_for_file("conf/#{file}")
        File.open(File.join(solr_dir, 'conf', file), 'wb') { |f| f.write(response.body) }
      end
    end

    def url_for_file(file)
      "https://git.psu.edu/i-tech/psulib_blacklight/raw/master/solr/#{file}"
    end
  end
end