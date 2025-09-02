# frozen_string_literal: true

source 'https://rubygems.org'

gem 'base64'
gem 'config'
gem 'library_stdnums'
gem 'mail'
gem 'marc'
gem 'rake'
gem 'redis'
gem 'rsolr'
gem 'shelvit'
gem 'traject'
gem 'traject-marc4j_reader', platform: :jruby
gem 'whenever', require: false

group :test do
  gem 'webmock'
end

group :development, :test do
  gem 'faker'
  gem 'marc_bot', '~> 0.2'
  gem 'pry-byebug', platform: :mri
  gem 'rspec'
  gem 'rspec-its'
  gem 'rubocop', '~> 1.5'
  gem 'rubocop-performance', '~> 1.1'
  gem 'rubocop-rspec', '~> 2'
  gem 'simplecov'
end
