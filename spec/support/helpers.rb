# frozen_string_literal: true

module Helpers
  def fixture_path
    Pathname.pwd.join('spec/fixtures')
  end

  def indexer
    @indexer
  end
end

RSpec.configure do |config|
  config.before(:all) do
    @indexer ||= Traject::Indexer.new.tap do |indexer|
      indexer.load_config_file('./config/traject.rb')
    end
  end

  config.include Helpers
end
