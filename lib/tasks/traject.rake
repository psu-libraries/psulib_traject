# frozen_string_literal: true

namespace :solr do
  desc 'Updates solr config files from psulib_blacklight'
  task :conf do
    solr_conf_dir = "#{Dir.pwd}/solr/conf"
    solr_files = ['protwords.txt', 'schema.xml', 'solrconfig.xml',
                  'stopwords.txt', 'stopwords_en.txt', 'synonyms.txt']

    solr_files.each do |file|
      response = Faraday.get url_for_file("solr/conf/#{file}")
      File.open("#{solr_conf_dir}/#{file}", 'w+') { |f| f.write(response.body) }
    end
  end

  task :last_incremented_collection do
    require './lib/psulib_traject/solr_manager'
    solr_manager = PsulibTraject::SolrManager.new
    puts solr_manager.last_incremented_collection
  end

  def url_for_file(file)
    "https://raw.githubusercontent.com/psu-libraries/psulib_blacklight/master/#{file}"
  end
end
