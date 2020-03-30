# frozen_string_literal: true

require 'rails'
require 'telegraf/rack'

module Telegraf
  class Railtie < ::Rails::Railtie
    config.telegraf = ::ActiveSupport::OrderedOptions.new

    # Connect URI or tuple
    config.telegraf.connect = ::Telegraf::Agent::DEFAULT_CONNECTION

    # Install rackmiddlewares
    config.telegraf.rack = ::ActiveSupport::OrderedOptions.new
    config.telegraf.rack.enabled = true
    config.telegraf.rack.series = 'requests'
    config.telegraf.rack.tags = {}

    # Install request instrumentation
    config.telegraf.instrumenation = true

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
      next unless app.config.telegraf.instrumenation

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
  end
end
