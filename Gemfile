source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails'

# auth
gem 'sorcery'

# pagination
gem 'kaminari'

# гемы для работы по отправке почты
gem 'mail'
gem 'concurrent-ruby', require: 'concurrent' # нужен для MyMailer (функция throttling)
gem 'concurrent-ruby-edge', require: 'concurrent-edge'
gem 'sanitize' # чистит html в письме

# gem 'mongoid'
# gem 'ostruct'

gem 'pg'
# gem 'pg_search'

gem 'redis'
gem 'connection_pool'

# для генерации pdf
# gem 'prawn'

# https://github.com/skroutz/greeklish/tree/master
# https://github.com/agorf/greeklish_iso843
# GreeklishIso843::GreekText.to_greeklish("Ευάγγελος") # => "Evangelos"
gem 'greeklish_iso843'
# gem 'greeklish'

# для определения браузера, отсеивания ботов
gem 'browser'

# https://github.com/rails/actionpack-page_caching
gem 'actionpack-page_caching'

gem 'rack-cors', :require => 'rack/cors'

# Use sqlite3 as the database for Active Record
gem "sqlite3"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma"

gem 'addressable'
gem 'httparty'

gem 'rmagick'

# https://github.com/halostatue/diff-lcs
# gem 'diff-lcs'

# html parser for prettify links in articles
gem 'nokogiri'

gem 'carrierwave'
# gem 'carrierwave-mongoid', require: 'carrierwave/mongoid'

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# gem 'amazing_print', require: false
gem 'sitemap_generator', require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

# group :test do
#   # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
#   gem "capybara"
#   gem "selenium-webdriver"
#   gem "webdrivers"
# end


# Было

# # The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
# gem "sprockets-rails"
# # Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# gem 'terser'
# gem 'mini_racer'

# СТАЛО:

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
# gem "jsbundling-rails"
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
# gem "cssbundling-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

gem "solid_queue", "~> 1.4"
