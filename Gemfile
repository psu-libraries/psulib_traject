# frozen_string_literal: true

source 'https://rubygems.org'

gem 'config'
gem 'lcsort'
gem 'library_stdnums'
gem 'mail'
gem 'marc'
gem 'rake'
gem 'rsolr'
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'traject'
gem 'traject-marc4j_reader', platform: :jruby
gem 'whenever', require: false

group :test do
  gem 'webmock'
end

group :development, :test do
  gem 'faker'
  gem 'marc_bot'
  gem 'pry-byebug', platform: :mri
  gem 'pry-debugger-jruby', platform: :jruby
  gem 'rspec'
  gem 'rspec-its'
  gem 'rubocop', '~> 0.79'
  gem 'rubocop-performance', '~> 1.1'
  gem 'rubocop-rspec', '~> 1.3'
  gem 'simplecov', '< 0.18' # CodeClimate does not work with .18 or later
end
