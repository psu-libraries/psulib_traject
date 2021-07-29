# frozen_string_literal: true

namespace :docker do
  def new
    port = ConfigSettings.solr.port || '8983'
    config = Pathname.pwd.join('solr/conf')
    args = %W(
      --name felix
      -d
      -p #{port}:8983
      -v #{config}:/myconfig solr:7.4.0 solr-create
      -c psul_catalog
      -d /myconfig
    )

    exec("docker run #{args.join(' ')}")
  end

  task :up do
    results = `docker inspect felix`
    results.strip!
    if results == '[]'
      new
    else
      Rake::Task['docker:start'].invoke
    end
  end

  task :clean do
    exec("docker exec -it felix post -c psul_catalog -d '<delete><query>*:*</query></delete>'")
  end

  task :pull do
    exec('docker pull solr:7.4.0')
  end

  task :start do
    exec('docker start felix')
  end

  task :conf do
    exec('docker exec -it felix cp -R /myconfig/. /opt/solr/server/solr/psul_catalog/conf/')
  end

  task :down do
    exec('docker stop felix')
  end

  task :ps do
    exec('docker ps')
  end
end
