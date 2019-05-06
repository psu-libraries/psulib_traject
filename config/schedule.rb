# frozen_string_literal: true

set :environment_variable, 'RUBY_ENVIRONMENT'
env 'MAILTO', 'cdm32@psu.edu'

# Process incrementals (adds/deletes from Symphony)
every :weekday, at: '04:10am' do
  rake 'incrementals:import_daily'
  rake 'incrementals:delete_daily'
end
