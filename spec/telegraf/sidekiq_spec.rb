# frozen_string_literal: true

require 'spec_helper'

require 'telegraf/sidekiq'
require 'tmpdir'

require 'sidekiq'
require 'sidekiq/testing'

class HardWorker
  include Sidekiq::Worker

  def perform(_message)
    # noop
  end
end

class FailWorker
  include Sidekiq::Worker

  def perform(message)
    raise message
  end
end

RSpec.describe Telegraf::Sidekiq::Middleware do
  subject(:work!) do
    queue!
    Sidekiq::Worker.drain_all
  end

  let(:queue!) { HardWorker.perform_async('test') }
  let(:socket) { UNIXServer.new "#{tmpdir}/sock" }
  let(:agent) { Telegraf::Agent.new "unix:#{tmpdir}/sock" }
  let(:args) { {} }

  before do
    Sidekiq::Testing.server_middleware do |chain|
      chain.add Telegraf::Sidekiq::Middleware, agent, args
    end

    Sidekiq::Worker.clear_all
  end

  context 'successful async execution' do
    it 'type=job,errors=false app_ms,queue_ms' do
      work!

      expect(last_point.series).to eq 'sidekiq'
      expect(last_point.tags).to include(
        'type' => 'job',
        'worker' => 'HardWorker',
        'queue' => 'default',
        'errors' => 'false',
        'retry' => 'false',
      )
      expect(last_point.values).to match 'app_ms' => /^\d+\.\d+$/, 'queue_ms' => /^\d+\.\d+$/
    end
  end

  context 'successful scheduled execution' do
    let(:queue!) { HardWorker.perform_at(Time.now.utc + 20, 'test') }

    it 'type=scheduled_job,errors=false app_ms' do
      work!

      expect(last_point.series).to eq 'sidekiq'
      expect(last_point.tags).to include(
        'type' => 'scheduled_job',
        'worker' => 'HardWorker',
        'queue' => 'default',
        'errors' => 'false',
        'retry' => 'false',
      )
      expect(last_point.values).to match 'app_ms' => /^\d+\.\d+$/
    end
  end

  context 'with error' do
    let(:queue!) { FailWorker.perform_async('test') }

    it 'type=job,errors=true app_ms,queue_ms' do
      begin
        work!
      rescue StandardError
        nil
      end

      expect(last_point.series).to eq 'sidekiq'
      expect(last_point.tags).to include(
        'type' => 'job',
        'worker' => 'FailWorker',
        'queue' => 'default',
        'errors' => 'true',
        'retry' => 'false',
      )
      expect(last_point.values).to match 'app_ms' => /^\d+\.\d+$/, 'queue_ms' => /^\d+\.\d+$/
    end
  end

  context 'with custom series name' do
    let(:args) { {series: 'background'} }

    it 'uses the custom series' do
      work!

      expect(last_point.series).to eq 'background'
      expect(last_point.tags).to include(
        'type' => 'job',
        'worker' => 'HardWorker',
        'queue' => 'default',
        'errors' => 'false',
        'retry' => 'false',
      )
      expect(last_point.values).to match 'app_ms' => /^\d+\.\d+$/, 'queue_ms' => /^\d+\.\d+$/
    end
  end

  context 'with extra tags' do
    let(:args) { {tags: {my: 'tag'}} }

    it 'adds the tag to the standard tags' do
      work!

      expect(last_point.series).to eq 'sidekiq'
      expect(last_point.tags).to include(
        'type' => 'job',
        'worker' => 'HardWorker',
        'queue' => 'default',
        'errors' => 'false',
        'retry' => 'false',
        'my' => 'tag',
      )
      expect(last_point.values).to match 'app_ms' => /^\d+\.\d+$/, 'queue_ms' => /^\d+\.\d+$/
    end
  end

  context 'with before_send filter' do
    let(:args) { {before_send: before_send} }

    context 'excluding specific worker' do
      let(:before_send) do
        lambda {|point, worker:, **|
          return if worker.instance_of?(HardWorker)

          point
        }
      end

      it('drops matching points') do
        work!
        expect(last_points.size).to eq 0
      end
    end
  end
end
