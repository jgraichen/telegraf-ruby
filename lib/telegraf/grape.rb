# frozen_string_literal: true

module Telegraf
  # Telegraf::Grape
  #
  # This class extends requests metrics with details for Grape API endpoints.
  #
  #
  # Tags:
  #
  # * `controller`:
  #     The Grape endpoint class.
  #
  # * `instance`:
  #     The Grape endpoint class.
  #
  # * `format`:
  #     Grape's internal identifier for the response format.
  #
  class Grape
    def call(_name, _start, _finish, _id, payload)
      point = payload[:env][::Telegraf::Rack::FIELD_NAME]
      return unless point

      endpoint = payload[:endpoint]
      return unless endpoint

      point.tags[:controller] = endpoint.options[:for].to_s
      point.tags[:instance] = point.tags[:controller]
      point.tags[:format] = payload[:env]['api.format']
    end
  end
end
