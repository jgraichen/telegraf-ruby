# frozen_string_literal: true

require 'rack'

module Telegraf
  module Plugin
    # Warning: `:values` member overrides `Struct#values` and it may be
    # unexpected, but nothing we can change here as this is an import public API
    # right now.
    #
    # rubocop:disable Lint/StructNewOverride
    Point = Struct.new(:tags, :values, keyword_init: true) do
      def initialize(tags: {}, values: {})
        super
      end
    end
    # rubocop:enable Lint/StructNewOverride

    def initialize(agent:, series:, tags: {}, before_send: nil, **)
      @agent = agent

      @tags = tags.freeze
      @series = String(series).freeze
      @before_send = before_send
    end

    def _write(point, before_send_kwargs: {})
      if @before_send
        point = @before_send.call(point, **before_send_kwargs)
        return unless point
      end

      @agent.write(@series, tags: point.tags, values: point.values)
    end
  end
end
