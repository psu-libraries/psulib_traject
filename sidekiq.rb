# frozen_string_literal: true

require 'pathname'

$LOAD_PATH.prepend(Pathname.pwd.join('lib').to_s)
require 'sidekiq'
require 'psulib_traject'
