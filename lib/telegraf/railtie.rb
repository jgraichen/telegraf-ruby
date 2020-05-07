# frozen_string_literal: true

require 'rails'
require 'telegraf/rack'
require 'telegraf/sidekiq'

module Telegraf
  # Telegraf::Railtie
  #
  # This Rails plugin installs the rack middleware and adds intrumentation to
  # enrich the data point with additional tags an values.
  #
  # These include the following tags:
  #
  # * `action`
  #     The controller action, e.g. `index`.
  #
  # * `controller`
  #     The controller class name, e.g. `API::UsersController`.
  #
  # * `instance`
  #     A combination of the controller class and the action, e.g.
  #     `API::UsersController#index`.
  #
  # * `method`
  #     The request method, e.g. `GET`.
  #
  # Additional collected values are:
  #
  # * `db_ms`
  #     Time spend with database operations in milliseconds.
  #
  # * `view_ms`
  #     Time spend with rendering views in milliseconds.
  #
  # * `action_ms`
  #     Total time spend in a Rails action in milliseconds.
  #
  # These additional tags and values are collection from the
  # `process_action.action_controller` events usings Rails instrumentation.
  #
  class Railtie < ::Rails::Railtie
    config.telegraf = ::ActiveSupport::OrderedOptions.new

    # Connect URI or tuple
    config.telegraf.connect = ::Telegraf::Agent::DEFAULT_CONNECTION

    # Install Rack middlewares
    config.telegraf.rack = ::ActiveSupport::OrderedOptions.new
    config.telegraf.rack.enabled = true
    config.telegraf.rack.series = 'requests'
    config.telegraf.rack.tags = {}

    # Install request instrumentation
    config.telegraf.instrumentation = true

    # Install Sidekiq middleware
    config.telegraf.sidekiq = ::ActiveSupport::OrderedOptions.new
    config.telegraf.sidekiq.enabled = defined?(::Sidekiq)
    config.telegraf.sidekiq.series = 'sidekiq'
    config.telegraf.sidekiq.tags = {}

    initializer 'telegraf.agent' do |app|
      app.config.telegraf.agent ||= begin
        ::Telegraf::Agent.new \
          app.config.telegraf.connect,
          logger: Rails.logger
      end
    end

    initializer 'telegraf.rack' do |app|
      next unless app.config.telegraf.rack.enabled

      app.config.middleware.insert 0, Telegraf::Rack, \
        agent: app.config.telegraf.agent,
        series: app.config.telegraf.rack.series,
        tags: app.config.telegraf.rack.tags,
        logger: Rails.logger
    end

    initializer 'telegraf.instrumentation' do |app|
      next unless app.config.telegraf.instrumentation

      ActiveSupport::Notifications.subscribe(
        'process_action.action_controller'
      ) do |_name, start, finish, _id, payload|
        point = payload[:headers].env[::Telegraf::Rack::FIELD_NAME]
        next unless point

        point.tags[:action] = payload[:action]
        point.tags[:controller] = payload[:controller]
        point.tags[:instance] = "#{payload[:controller]}##{payload[:action]}"
        point.tags[:method] = payload[:method]

        point.values[:db_ms] = payload[:db_runtime].to_f
        point.values[:view_ms] = payload[:view_runtime].to_f
        point.values[:action_ms] = ((finish - start) * 1000.0) # milliseconds
      end
    end

    initializer 'telegraf.sidekiq' do |app|
      next unless app.config.telegraf.sidekiq.enabled

      ::Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add Telegraf::Sidekiq::Middleware, \
            agent: app.config.telegraf.agent,
            series: app.config.telegraf.sidekiq.series,
            tags: app.config.telegraf.sidekiq.tags
        end
      end
    end
  end
end
