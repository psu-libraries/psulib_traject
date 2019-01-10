# frozen_string_literal: true

require 'faraday'

namespace :solr do
  desc 'Updates solr config files from psulib_blacklight'
  task :conf do
    solr_files = ['protwords.txt', 'schema.xml', 'solrconfig.xml',
                  'stopwords.txt', 'stopwords_en.txt', 'synonyms.txt']

    solr_files.each do |file|
      response = Faraday.get url_for_file("solr/conf/#{file}")
      File.open("#{Dir.pwd}/solr/conf/#{file}", 'w+') { |f| f.write(response.body) }
    end
  end

  def url_for_file(file)
    "https://raw.githubusercontent.com/psu-libraries/psulib_blacklight/master/#{file}"
  end
end
