# frozen_string_literal: true

require 'faraday'

namespace :solr do
  desc 'Updates solr config files from psulib_blacklight'
  task :conf do
    solr_dir = "#{File.dirname(__FILE__)}/solr"
    solr_files = ['protwords.txt', 'schema.xml', 'solrconfig.xml',
                  'stopwords.txt', 'stopwords_en.txt', 'synonyms.txt', ]

    solr_files.each do |file|
      response = Faraday.get url_for_file("solr/conf/#{file}")
      File.open(File.join(solr_dir, 'conf', file), 'wb') { |f| f.write(response.body) }
    end
  end

  task :up do
    container_status = `docker inspect felix`
    container_status.strip!

    if container_status == '[]'
      Rake::Task['docker:start'].invoke
    else
      print `docker start felix`
    end

    Rake::Task['solr:ps'].invoke
  end

  task :clean do
    print `docker exec -it felix \
            post -c blacklight-core \
                 -d '<delete><query>*:*</query></delete>' -out 'yes'`
  end

  task :start do
    print `docker pull solr:7.4.0`
    print `docker run \
            --name felix \
            -p 8983:8983 \
            -v "$(pwd)"/solr/conf:/myconfig \
            solr:7.4.0 \
            solr-create -c blacklight-core -d /myconfig`
  end

  task :down do
    print `docker stop felix`
  end

  task :ps do
    print `docker ps`
  end

  def url_for_file(file)
    "https://raw.githubusercontent.com/psu-libraries/psulib_blacklight/%23175-schema-updates/#{file}"
  end
end
