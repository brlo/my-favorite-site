require_relative "boot"

# require "rails/all"

# See https://github.com/rails/rails/blob/v6.0.2.1/railties/lib/rails/all.rb for the list
# of what is being included here
require "rails"

# This list is here as documentation only - it's not used
omitted = %w(
  active_storage/engine
  action_cable/engine
  action_mailbox/engine
  action_text/engine
)

# Only the frameworks in Rails that do not pollute our routes
%w(
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  rails/test_unit/railtie
  sprockets/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bibleox
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA256

    # bibleox.com
    # res.bibleox.com
    config.hosts << /([a-z0-9-]+\.)?([a-z0-9-]+\.)?bibleox\.com/
    config.hosts << /([a-z0-9-]+\.)?([a-z0-9-]+\.)?bibleox\.lan/

    config.i18n.default_locale = :ru

    config.action_controller.page_cache_directory = Rails.root.join("public", "cached_pages")

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Europe/Moscow"

    # config.eager_load_paths << Rails.root.join("extras")

    # Autoload lib, but do not eager load it (maybe overlooked).
    config.autoload_paths << config.root.join("lib")
  end
end
