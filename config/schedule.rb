# frozen_string_literal: true

set :environment_variable, 'RUBY_ENVIRONMENT'

# Process incrementals (adds/deletes from Symphony) daily
every :weekday, at: '04:10am' do
  rake "incrementals:import['daily']"
  rake "incrementals:delete['daily']"
end

# Process incrementals (adds/deletes from Symphony) hourly (3 minutes past the hour everyday between 7am and midnight)
every '3 0,7-23 * * *' do
  rake "incrementals:import['hourly']"
  rake "incrementals:delete['hourly']"
end
