# frozen_string_literal: true

$LOAD_PATH.prepend(Pathname.pwd.join('lib').to_s)
ENV['RUBY_ENVIRONMENT'] ||= 'dev'
require 'psulib_traject'

Dir.glob('lib/tasks/*.rake').each { |r| load r }

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec
