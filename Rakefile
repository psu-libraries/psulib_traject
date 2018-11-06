# frozen_string_literal: true

namespace :solr do
  desc 'Updates .solr_wrapper.yml and solr config files from gitlab'
  task :conf do
    solr_dir = "#{File.dirname(__FILE__)}/solr"
    solr_files = ['elevate.xml', 'mapping-ISOLatin1Accent.txt', 'protwords.txt', 'schema.xml',
                 'scripts.conf', 'solrconfig.xml', 'spellings.txt', 'stopwords.txt', 'stopwords_en.txt',
                 'synonyms.txt', 'admin-extra.html', '_rest_managed.json']

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

    Rake::Task['docker:ps'].invoke
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

  def url_for_file(file)
    "https://raw.githubusercontent.com/psu-libraries/psulib_blacklight/master/#{file}"
  end
end
