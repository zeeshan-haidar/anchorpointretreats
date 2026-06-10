source 'https://rubygems.org'

ruby '3.3.8'

# Core
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
gem 'rails', '~> 7.1.6'
gem 'redis'
gem 'sidekiq'
gem 'sprockets-rails'

# Frontend
gem 'importmap-rails'
gem 'jbuilder'
gem 'stimulus-rails'
gem 'turbo-rails'

# Auth & Authorization
gem 'cancancan'
gem 'devise'

# Payments
gem 'stripe'

# Image Upload
gem 'aws-sdk-s3', require: false
gem 'image_processing', '~> 1.2'

# Email
gem 'resend', require: false

# Utilities
gem 'pagy'
gem 'rack-attack'
gem 'ransack'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mswin mswin64 mingw x64_mingw jruby]

gem 'dotenv-rails'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

group :development, :test do
  gem 'debug', platforms: %i[mri mswin mswin64 mingw x64_mingw]
  gem 'rails-controller-testing'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  gem 'annotate'
  gem 'error_highlight', platforms: [:ruby]
  gem 'letter_opener_web'
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end
