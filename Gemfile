# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in telegraf.gemspec
gemspec

gem 'rake'
gem 'rake-release', '~> 1.2'

gem 'rspec', '~> 3.8'
gem 'rspec-github', require: false

gem 'rubocop-config', github: 'jgraichen/rubocop-config', tag: 'v14'

group :test do
  gem 'rack'
  gem 'rails'
  gem 'sidekiq'
  gem 'timecop'
end

group :development do
  gem 'appraisal'
end
