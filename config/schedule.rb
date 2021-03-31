# frozen_string_literal: true

set :environment_variable, 'RUBY_ENVIRONMENT'
# Overrides the default :rake job type of
# job_type :rake,    "cd :path && :environment_variable=:environment bundle exec rake :task --silent :output"
job_type :rake,    "cd :path && JRUBY_OPTS=\"-J-Xmx4028m\" :environment_variable=:environment bundle exec rake :task --silent :output"

# Process incrementals (adds/deletes from Symphony) daily
# Changes to this schedule should be reflected in the "Traject Incrementals (daily)" alert in splunk
every :day, at: '04:10am' do
  rake "incrementals:import['daily']"
  rake "incrementals:delete['daily']"
end

# Process incrementals (adds/deletes from Symphony) hourly (3 minutes past the hour everyday between 7am and midnight)
# Changes to this schedule should be reflected in the "Traject Incrementals" alert in splunk
every '3 0,7-23 * * *' do
  rake "incrementals:import['hourly']"
  rake "incrementals:delete['hourly']"
end
