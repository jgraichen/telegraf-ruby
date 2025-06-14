# frozen_string_literal: true

require 'spec_helper'

require 'rack/mock'
require 'telegraf/rack'
require 'tmpdir'

require 'logger'

RSpec.describe Telegraf::Rack do
  subject(:mock) do
    Rack::MockRequest.new(described_class.new(app, agent: agent, **args))
  end

  let(:socket) { UNIXServer.new "#{tmpdir}/sock" }
  let(:agent) { Telegraf::Agent.new "unix:#{tmpdir}/sock" }
  let(:args) { {} }

  let(:app) { ->(_env) { [200, {}, []] } }

  context 'with successful request' do
    it 'status=200 app_ms,send_ms,request_ms' do
      mock.request
      expect(socket_read).to match(/\Arack,status=200 app_ms=\d+\.\d+,request_ms=\d+\.\d+,send_ms=\d+\.\d+\z/)
    end
  end

  context 'with a 404 response' do
    let(:app) { ->(_env) { [404, {}, []] } }

    it 'includes status=404' do
      mock.request
      expect(last_points.size).to eq 1
      expect(last_point.tags).to eq 'status' => '404'
    end
  end

  context 'with error' do
    let(:app) { ->(_env) { raise 'fail' } }

    it 'status=-1 app_ms,request_ms' do
      mock.request rescue nil
      expect(last_points.size).to eq 1
      expect(last_point.tags).to eq 'status' => '-1'
      expect(last_point.values.keys).to match_array %w[app_ms request_ms]
    end
  end

  context 'with X-Request-Start' do
    before do
      mock.request('GET', '/', {'HTTP_X_REQUEST_START' => "t=#{timestamp}"})
    end

    around do |example|
      Timecop.freeze(Time.at(1_234_567_891)) { example.run }
    end

    context 'floating point timestamp in seconds' do
      let(:timestamp) { '1234567890.750' }

      it 'includes queue_ms value' do
        expect(last_points.size).to eq 1
        expect(last_point.values.keys).to include 'queue_ms'
        expect(last_point.values['queue_ms']).to eq '250.0'
      end
    end

    context 'integer timestamp in milliseconds' do
      let(:timestamp) { '1234567890750' }

      it 'includes queue_ms value' do
        expect(last_points.size).to eq 1
        expect(last_point.values.keys).to include 'queue_ms'
        expect(last_point.values['queue_ms']).to eq '250.0'
      end
    end

    context 'integer timestamp in microseconds' do
      let(:timestamp) { '1234567890500251' }

      it 'includes queue_ms value' do
        expect(last_points.size).to eq 1
        expect(last_point.values.keys).to include 'queue_ms'
        expect(last_point.values['queue_ms']).to eq '499.749'
      end
    end

    context 'integer timestamp in nanoseconds' do
      let(:timestamp) { '1234567890500000251' }

      it 'includes queue_ms value' do
        expect(last_points.size).to eq 1
        expect(last_point.values.keys).to include 'queue_ms'
        expect(last_point.values['queue_ms']).to eq '499.999749'
      end
    end
  end

  context 'with extra tags and values' do
    let(:app) do
      lambda do |env|
        env['telegraf.rack.point'].tags[:my] = 'tag'
        env[Telegraf::Rack::FIELD_NAME].values[:val] = 100

        [200, {}, []]
      end
    end

    it 'status=200 app_ms,send_ms,request_ms' do
      mock.request

      expect(last_points.size).to eq 1
      expect(last_point.tags).to include 'my' => 'tag'
      expect(last_point.values).to include 'val' => '100i'
    end
  end

  context 'with write error' do
    before { allow(agent).to receive(:write).and_raise('write failed') }

    let(:io) { StringIO.new }

    it 'logs error to rack logger' do
      mock.request('GET', '/', {'rack.logger' => Logger.new(io)})

      expect(io.string).to match(/ERROR .* write failed \(RuntimeError\)/)
    end

    context 'with explicitly given logger' do
      let(:args) { {logger: Logger.new(io)} }

      it 'logs error to given logger' do
        rackio = StringIO.new
        mock.request('GET', '/', {'rack.logger' => Logger.new(rackio)})

        expect(io.string).to match(/ERROR .* write failed \(RuntimeError\)/)
        expect(rackio.string).to be_empty
      end
    end

    context 'without logger' do
      it 'nothing happens' do
        expect do
          mock.request('GET', '/', {'rack.logger' => nil})
        end.not_to raise_error
      end
    end
  end

  context 'with before_send filter' do
    let(:args) { {before_send: before_send} }

    context 'dropping rack paths' do
      let(:before_send) do
        lambda {|point, request:, **|
          return if %r{^/healthcheck}.match?(request.path)

          point.values[:path] = request.path
          point
        }
      end

      it 'drops matching points' do
        mock.request('GET', '/', {})
        mock.request('GET', '/healthcheck', {})

        expect(last_points.size).to eq 1
        expect(last_point.values).to include('path' => '"/"')
      end
    end
  end
end
