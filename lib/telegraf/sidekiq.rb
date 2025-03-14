# frozen_string_literal: true

require 'rack'

module Telegraf
  module Sidekiq
    # Telegraf::Sidekiq::Middleware
    #
    # This Sidekiq middleware collects queue metrics and sends them to telegraf.
    #
    #
    # Tags:
    #
    # * `type`:
    #     One of "job" or "scheduled_job".
    #
    # * `queue`:
    #     The queue this job landed on.
    #
    # * `worker`:
    #     The name of the worker class that was executed.
    #
    # * `errors`:
    #     Whether or not this job errored.
    #
    # * `retry`:
    #     Whether or not this execution was a retry of a previously failed one.
    #
    #
    # Values:
    #
    # * `app_ms`:
    #     Total worker processing time.
    #
    # * `queue_ms`:
    #     How long did this job wait in the queue before being processed?
    #     Only present for "normal" (async) jobs (with tag `type` of "job").
    #
    class Middleware
      include ::Telegraf::Plugin

      def initialize(agent, options = {})
        options[:series] ||= 'sidekiq'

        super(
          **options,
          agent: agent
        )
      end

      def call(worker, job, queue)
        job_start = ::Time.now.utc

        point = Point.new(
          tags: {
            **@tags,
            type: 'job',
            errors: true,
            retry: job.key?('retried_at'),
            queue: queue,
            worker: worker.class.name,
          },
          values: {
            retry_count: job['retry_count'],
          }.compact,
        )

        # The "enqueued_at" key is not present for scheduled jobs.
        # See https://github.com/mperham/sidekiq/wiki/Job-Format.
        if job.key?('enqueued_at')
          enqueued_at = Time.at(
            if defined?(::Sidekiq::MAJOR) && ::Sidekiq::MAJOR >= 8
              job['enqueued_at'].to_f / 1000
            else
              job['enqueued_at'].to_f
            end,
          ).utc

          point.values[:queue_ms] = (job_start - enqueued_at) * 1000 # milliseconds
        end

        # The "at" key is only present for scheduled jobs.
        point.tags[:type] = 'scheduled_job' if job.key?('at')

        begin
          yield

          # If we get here, this was a successful execution
          point.tags[:errors] = false
        ensure
          job_stop = ::Time.now.utc

          point.values[:app_ms] = (job_stop - job_start) * 1000 # milliseconds

          _write(point, before_send_kwargs: {worker: worker, job: job, queue: queue})
        end
      end
    end
  end
end
