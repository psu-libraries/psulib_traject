require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Sidekiq.configure_client do |config|
  config.redis = { size: 1 }
end

use Rack::Session::Cookie, secret: ENV.fetch('SESSION_KEY', nil), same_site: true, max_age: 86400
map '/sidekiq' do
  run Sidekiq::Web
end
