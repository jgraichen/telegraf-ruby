# frozen_string_literal: true

require 'spec_helper'

require 'telegraf'

RSpec.describe Telegraf::Agent do
  subject(:agent) { Telegraf::Agent.new("unix:#{tmpdir}/sock", **kwargs) }

  let(:kwargs) { {} }
  let(:socket) { UNIXServer.new "#{tmpdir}/sock" }

  describe '#write' do
    context 'with tags' do
      let(:kwargs) { {tags: {app: 'test', tagged: 'yes'}} }

      it 'merges tags into event' do
        # Write app tag here too to ensure it is overwritten by global tags
        agent.write('series', tags: {app: 'no', field: 'yes'}, values: {a: 1})
        expect(socket_read).to eq 'series,app=test,field=yes,tagged=yes a=1i'
      end
    end
  end
end
