# frozen_string_literal: true

require 'spec_helper'

require 'telegraf/active_job'
require 'tmpdir'

require 'logger'
require 'active_job'

class HardJob < ActiveJob::Base
  def perform(_message)
    # noop
  end
end

class FailJob < ActiveJob::Base
  def perform(message)
    raise message
  end
end

RSpec.describe Telegraf::ActiveJob do
  subject(:work!) { HardJob.perform_now 'test' }

  let(:socket) { UNIXServer.new "#{tmpdir}/sock" }
  let(:agent) { Telegraf::Agent.new "unix:#{tmpdir}/sock" }
  let(:args) { {} }

  before do
    ActiveSupport::Notifications.subscribe(
      'perform.active_job',
      Telegraf::ActiveJob.new(agent: agent, **args),
    )

    ActiveJob::Base.logger = Logger.new(IO::NULL)
  end

  context 'successful async execution' do
    it 'job=HardJob,queue=default,errors=false app_ms' do
      work!

      expect(last_point.series).to eq 'active_job'
      expect(last_point.tags).to include 'job' => 'HardJob', 'queue' => 'default', 'errors' => 'false'
      expect(last_point.values).to match 'app_ms' => /^\d+\.\d+$/
    end
  end

  context 'with error' do
    subject(:work!) { FailJob.perform_now 'test' }

    it 'job=HardJob,queue=default,errors=true app_ms' do
      work! rescue nil

      expect(last_point.series).to eq 'active_job'
      expect(last_point.tags).to include 'job' => 'FailJob', 'queue' => 'default', 'errors' => 'true'
      expect(last_point.values).to match 'app_ms' => /^\d+\.\d+$/
    end
  end

  context 'with custom series name' do
    let(:args) { {series: 'background'} }

    it 'uses the custom series' do
      work!

      expect(last_point.series).to eq 'background'
      expect(last_point.tags).to include 'job' => 'HardJob', 'queue' => 'default', 'errors' => 'false'
      expect(last_point.values).to match 'app_ms' => /^\d+\.\d+$/
    end
  end

  context 'with extra tags' do
    let(:args) { {tags: {my: 'tag'}} }

    it 'adds the tag to the standard tags' do
      work!

      expect(last_point.series).to eq 'active_job'
      expect(last_point.tags).to include 'job' => 'HardJob', 'queue' => 'default', 'errors' => 'false', 'my' => 'tag'
      expect(last_point.values).to match 'app_ms' => /^\d+\.\d+$/
    end
  end
end
