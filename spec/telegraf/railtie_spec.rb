# frozen_string_literal: true

require 'spec_helper'
require 'telegraf/rails'

require 'action_controller'

ENV['RAILS_ENV'] ||= 'production'

class TestController < ::ActionController::Base
  def index
    render plain: 'test'
  end
end

RSpec.describe Telegraf::Railtie do
  subject(:app) do
    Class.new(::Rails::Application) do
      config.eager_load = true
      config.secret_key_base = 'secret'
      config.action_dispatch.show_exceptions = false

      routes.append do
        get '/' => 'test#index'
      end
    end
  end

  around do |example|
    defaults = config.telegraf.deep_dup
    begin
      example.run
    ensure
      config.telegraf = defaults
    end
  end

  let(:config) { app.config }
  let(:application) { app.tap(&:initialize!) }

  describe '<config>' do
    describe 'telegraf.connect' do
      it 'defaults to ::Telegraf::Agent::DEFAULT_CONNECTION' do
        expect(config.telegraf.connect).to eq ::Telegraf::Agent::DEFAULT_CONNECTION
      end
    end

    describe 'telegraf.tags' do
      subject { config.telegraf.tags }
      it { is_expected.to eq({}) }
    end

    describe 'telegraf.rack.enabled' do
      subject { config.telegraf.rack.enabled }
      it { is_expected.to eq true }
    end

    describe 'telegraf.rack.series' do
      subject { config.telegraf.rack.series }
      it { is_expected.to eq 'requests' }
    end

    describe 'telegraf.rack.tags' do
      subject { config.telegraf.rack.tags }
      it { is_expected.to eq({}) }
    end
  end

  describe '<initialize>' do
    it 'creates a telegraf agent' do
      config.telegraf.connect = 'tcp://localhost:1234'
      config.telegraf.tags = {app: 'name'}

      application.config.telegraf.agent.tap do |agent|
        expect(agent).to be_a ::Telegraf::Agent
        expect(agent.uri).to eq URI.parse('tcp://localhost:1234')
        expect(agent.tags).to eq({app: 'name'})
      end
    end

    it 'installs middleware in first place' do
      middleware = application.config.middleware.first
      expect(middleware.klass).to eq ::Telegraf::Rack

      kwargs = middleware.args.first
      expect(kwargs[:agent]).to eq application.config.telegraf.agent
      expect(kwargs[:series]).to eq 'requests'
      expect(kwargs[:tags]).to eq({})
    end

    context 'with rack disabled' do
      before { config.telegraf.rack.enabled = false }

      it 'does not install middleware' do
        expect(application.config.middleware.to_a).not_to include ::Telegraf::Rack
      end
    end
  end

  describe '<instrumentation>' do
    let(:mock) { ::Rack::MockRequest.new(application) }
    let(:socket) { UDPSocket.new.tap {|s| s.bind('localhost', 8094) } }

    it 'assigns extra tags and values' do
      expect(application.config.middleware).to include ::Telegraf::Rack
      mock.request

      parsed = socket_parse
      expect(parsed.size).to eq 1
      expect(parsed[0].series).to eq 'requests'
      expect(parsed[0].tags).to eq({
        'action' => 'index',
        'controller' => 'TestController',
        'instance' => 'TestController#index',
        'method' => 'GET',
        'status' => '200'
      })
      expect(parsed[0].values.keys).to match_array %w[action_ms app_ms db_ms request_ms send_ms view_ms]
    end

    context 'with global tags' do
      before { config.telegraf.rack.tags = {my: 'tag'} }

      it 'include global tags' do
        mock.request
        expect(socket_parse[0].tags).to include 'my' => 'tag'
      end
    end
  end
end
