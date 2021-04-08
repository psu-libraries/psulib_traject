# frozen_string_literal: true

source 'https://rubygems.org'

gem 'config'
gem 'library_stdnums'
gem 'mail'
gem 'marc'
gem 'rake'
gem 'rsolr'
gem 'traject'
gem 'traject-marc4j_reader', platform: :jruby
gem 'whenever', require: false

group :test do
  gem 'webmock'
end

group :development, :test do
  gem 'rspec'
  gem 'rubocop'
  gem 'simplecov', '< 0.18' # CodeClimate does not work with .18 or later
end

group :development do
  gem 'pry'
  gem 'pry-debugger-jruby'
end
