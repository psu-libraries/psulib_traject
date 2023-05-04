# frozen_string_literal: true
require_relative '../psulib_traject/update_locations'

namespace :locations do
  desc 'Updates lib/translation_maps/locations.properties with new locations info from Symphony'
  task :update do
    UpdateLocations.call    
  end
end
