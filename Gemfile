source "https://rubygems.org"

gem 'marc'
gem 'traject', '2.3.4'

#Check if we are using jruby and store.
is_jruby = RUBY_ENGINE == 'jruby'
if is_jruby
  gem 'traject-marc4j_reader'
else
  gem 'byebug'
end
