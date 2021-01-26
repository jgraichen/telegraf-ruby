# frozen_string_literal: true

require 'rack'

module Telegraf
  # Telegraf::Rack
  #
  # This rack middleware collects request metrics and sends them to the telegraf
  # agent. A `Point` data structure is added to the Rack environment to assign
  # custom tags and values. This point can be accessed using the environment key
  # defined in `::Telegraf::Rack::FIELD_NAME`.
  #
  # Example:
  #
  #     if (point = request.env[::Telegraf::Rack::FIELD_NAME])
  #       point.tags[:tag] = 'tag'
  #       point.values[:value] = 10
  #     end
  #
  #
  # Tags:
  #
  # * `status`:
  #     Response status unless request errored
  #
  #
  # Values:
  #
  # * `request_ms`:
  #     Total request processing time including response sending.
  #
  # * `app_ms`:
  #     Total application processing time.
  #
  # * `send_ms`:
  #     Time took to send the response body.
  #
  # * `queue_ms`:
  #     Queue time calculated from a `X-Request-Start` header if present. The
  #     header is expected to be formatted like this `t=<timestamp>` and
  #     contain a floating point timestamp in seconds.
  #
  class Rack
    FIELD_NAME = 'telegraf.rack.point'
    HEADER_REGEX = /t=(\d+(\.\d+)?)/.freeze

    # Warning: `:values` member overrides `Struct#values` and it may be
    # unexpected, but nothing we can change here as this is an import public API
    # right now.
    #
    # rubocop:disable Lint/StructNewOverride
    Point = Struct.new(:tags, :values)
    # rubocop:enable Lint/StructNewOverride

    def initialize(app, agent:, series: 'rack', tags: {}, logger: nil)
      @app = app
      @tags = tags.freeze
      @agent = agent
      @series = series.to_s.freeze
      @logger = logger
    end

    def call(env)
      if (request_start = extract_request_start(env))
        queue_ms = (::Time.now.utc - request_start) * 1000 # milliseconds
      end

      rack_start = ::Rack::Utils.clock_time
      point = env[FIELD_NAME] = Point.new(@tags.dup, {})
      point.values[:queue_ms] = queue_ms if queue_ms

      begin
        begin
          status, headers, body = @app.call(env)
        ensure
          point.tags[:status] ||= status || -1
          point.values[:app_ms] = \
            (::Rack::Utils.clock_time - rack_start) * 1000 # milliseconds
        end

        send_start = ::Rack::Utils.clock_time
        proxy = ::Rack::BodyProxy.new(body) do
          point.values[:send_ms] = \
            (::Rack::Utils.clock_time - send_start) * 1000 # milliseconds

          finish(env, point, rack_start)
        end

        [status, headers, proxy]
      ensure
        finish(env, point, rack_start) unless proxy
      end
    end

    private

    def finish(env, point, rack_start)
      point.values[:request_ms] = \
        (::Rack::Utils.clock_time - rack_start) * 1000 # milliseconds

      @agent.write(@series, tags: point.tags, values: point.values)
    rescue StandardError => e
      (@logger || env[::Rack::RACK_LOGGER])&.error(e)
    end

    def extract_request_start(env)
      return unless env.key?('HTTP_X_REQUEST_START')

      if (m = HEADER_REGEX.match(env['HTTP_X_REQUEST_START']))
        ::Time.at(m[1].to_f).utc
      end
    rescue FloatDomainError
      # Ignore obscure floats in Time.at (e.g. infinity)
      false
    end
  end
end
