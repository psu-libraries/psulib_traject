# frozen_string_literal: true

module PsulibTraject
  class Worker
    include Sidekiq::Worker

    require 'config'
    Config.setup do |config|
      config.const_name = 'ConfigSettings'
      config.use_env = true
      config.env_prefix = 'SETTINGS'
      config.env_separator = '__'
      config.load_and_set_settings(Config.setting_files('config', ENV['RUBY_ENVIRONMENT']))
    end
  end
end
