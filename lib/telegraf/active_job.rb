# frozen_string_literal: true

module Telegraf
  # Telegraf::ActiveJob
  #
  # This class collects ActiveJob queue metrics and sends them to telegraf.
  #
  #
  # Tags:
  #
  # * `queue`:
  #     The queue this job landed on.
  #
  # * `job`:
  #     The name of the job class that was executed.
  #
  # * `errors`:
  #     Whether or not this job errored.
  #
  #
  # Values:
  #
  # * `app_ms`:
  #     Total job processing time.
  #
  class ActiveJob
    include Plugin

    def initialize(series: 'active_job', **kwargs)
      super(series: series, **kwargs)
    end

    def call(_name, start, finish, _id, payload)
      job = payload[:job]

      point = Point.new(
        tags: {
          **@tags,
          job: job.class.name,
          queue: job.queue_name,
          errors: payload.key?(:exception_object),
        },
        values: {
          app_ms: ((finish - start) * 1000.0), # milliseconds
        },
      )

      _write(point, before_send_kwargs: {payload: payload})
    end
  end
end
