# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in telegraf.gemspec
gemspec

gem 'my-rubocop', github: 'jgraichen/my-rubocop', ref: 'v6'
gem 'rake'
gem 'rspec', '~> 3.8'

group :test do
  gem 'rack'
  gem 'rails'
  gem 'sidekiq', '~> 6.0'
end

group :development do
  gem 'appraisal'
  gem 'rake-release', '~> 1.2'
end
