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
        agent.write!('series', tags: {app: 'no', field: 'yes'}, values: {a: 1})
        expect(socket_read).to eq 'series,app=test,field=yes,tagged=yes a=1i'
      end
    end
  end

  describe '@before_send' do
    let(:kwargs) { {before_send: before_send} }
    let(:before_send) do
      lambda {|data|
        data.delete_if {|line| line[:tags].key?(:drop) }
        data
      }
    end

    it 'drops all points' do
      agent.write!('series', tags: {drop: 1}, values: {a: 1})
      expect { socket_read }.to raise_error(EOFError)
    end

    it 'drops matching points' do
      agent.write!('series', tags: {drop: 1}, values: {a: 1})
      agent.write!('series', tags: {field: 'yes'}, values: {a: 1})

      expect { socket_read }.to raise_error(EOFError)
      expect(socket_read).to eq 'series,field=yes a=1i'
    end

    it 'drops matching points in bulk mode' do
      agent.write!([
        {series: 'series', tags: {drop: 1}, values: {a: 1}},
        {series: 'series', tags: {field: 'yes'}, values: {a: 1}},
      ])

      expect(socket_read).to eq 'series,field=yes a=1i'
    end
  end
end
