require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bibleox
  class Application < Rails::Application
    config.active_record.legacy_connection_handling = false

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # bibleox.com
    # res.bibleox.com
    config.hosts << /([a-z0-9-]+\.)?([a-z0-9-]+\.)?bibleox\.com/
    config.hosts << /([a-z0-9-]+\.)?([a-z0-9-]+\.)?bibleox\.lan/

    config.i18n.default_locale = :ru

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Europe/Moscow"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
