# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in telegraf.gemspec
gemspec

gem 'rake'
gem 'rspec', '~> 3.8'
gem 'rspec-github', require: false

gem 'rubocop-config', github: 'jgraichen/rubocop-config', ref: '64e4c81870e869a3bdd9ea3c49fd042b321dbfbd'

group :test do
  gem 'rack'
  gem 'rails'
  gem 'sidekiq'
end

group :development do
  gem 'appraisal'
  gem 'rake-release', '~> 1.2'
end
