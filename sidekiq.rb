# frozen_string_literal: true

require 'pathname'

$LOAD_PATH.prepend(Pathname.pwd.join('lib').to_s)
require 'sidekiq'
require 'psulib_traject'
require 'sidekiq-reliable-fetch'

Sidekiq.configure_server do |config|
    Sidekiq::ReliableFetch.setup_reliable_fetch!(config)
end


