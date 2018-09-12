# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'solr_wrapper/rake_task'

namespace :psulib_traject do
  desc "Ingest the given marc file or the sample file"
  task :ingest do
    ARGV.each { |a| task a.to_sym do ; end }
    puts ARGV[1]
    if ARGV[1]
      `rbenv local jruby-9.2.0.0 && bundle exec bundle install && bundle exec traject -c psulib_config.rb #{ARGV[1]}`
    else
      `rbenv local jruby-9.2.0.0 && bundle exec bundle install && bundle exec traject -c psulib_config.rb solr/sample_data/demo_psucat.mrc`
    end
  end

  desc "Solr clean"
  task :solr_clean do
      `rbenv local 2.5.1 && bundle exec bundle install && bundle exec solr_wrapper -d .solr_wrapper.yml clean`
    end

  desc "Solr start"
  task :solr_start do
      `rbenv local 2.5.1 && bundle exec bundle install && bundle exec solr_wrapper`
    end
end