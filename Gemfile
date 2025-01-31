# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in telegraf.gemspec
gemspec

gem 'rake'
gem 'rspec', '~> 3.8'
gem 'rspec-github', require: false

gem 'rubocop-config', github: 'jgraichen/rubocop-config', ref: '9f3e5cd0e519811a7f615f265fca81a4f4e843b9'

group :test do
  gem 'rack'
  gem 'rails'
  gem 'sidekiq'
end

group :development do
  gem 'appraisal'
  gem 'rake-release', '~> 1.2'
end
