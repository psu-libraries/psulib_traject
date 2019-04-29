# Process incrementals (adds/deletes from Symphony)
every :weekday, at: '08:00am' do
  rake 'incrementals:import_daily'
  rake 'incrementals:delete_daily'
end
