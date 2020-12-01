# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in telegraf.gemspec
gemspec

gem 'rake'
gem 'rspec', '~> 3.8'
gem 'rubocop', '~> 0.80.0'

group :test do
  gem 'rack'
  gem 'railties'
  gem 'sidekiq', '~> 6.0'
end

group :development do
  gem 'appraisal'
  gem 'rake-release', '~> 1.2'
end
