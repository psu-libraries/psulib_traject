# frozen_string_literal: true

require 'faker'
require 'marc_bot'

RSpec.configure do |config|
  config.before(:suite) do
    MarcBot.reload
  end
end
