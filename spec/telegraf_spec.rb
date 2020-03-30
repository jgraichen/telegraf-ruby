# frozen_string_literal: true

require 'spec_helper'

require 'tmpdir'

RSpec.describe Telegraf do
  it 'has a version number' do
    expect(Telegraf::VERSION).not_to be nil
  end

  context 'with UNIX socket' do
    let(:agent) { ::Telegraf::Agent.new "unix:#{tmpdir}/sock" }
    let(:socket) { ::UNIXServer.new "#{tmpdir}/sock" }

    it 'writes multiple points' do
      agent.write(
        [
          {series: 'demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1}},
          {series: 'demo', tags: {a: '1', b: 2}, values: {a: 6, b: 2.5}}
        ]
      )

      expect(socket_read).to eq "demo,a=1,b=2 a=1i,b=2.1\ndemo,a=1,b=2 a=6i,b=2.5"
    end

    it 'writes single points' do
      agent.write('demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1})
      expect(socket_read).to eq 'demo,a=1,b=2 a=1i,b=2.1'
    end
  end

  context 'with UNIXGRAM socket' do
    let(:agent) { ::Telegraf::Agent.new "unixgram:#{tmpdir}/sock" }
    let(:socket) do
      Socket.new(:UNIX, :DGRAM).tap do |socket|
        socket.bind Socket.pack_sockaddr_un "#{tmpdir}/sock"
      end
    end

    it 'write points' do
      agent.write('demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1})
      expect(socket_read).to eq 'demo,a=1,b=2 a=1i,b=2.1'
    end
  end

  context 'with TCP socket' do
    let(:agent) { ::Telegraf::Agent.new 'tcp://localhost:8094' }
    let(:socket) { TCPServer.new 'localhost', 8094 }

    it 'write points' do
      agent.write('demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1})
      expect(socket_read).to eq 'demo,a=1,b=2 a=1i,b=2.1'
    end
  end

  context 'with UDP socket' do
    let(:agent) { ::Telegraf::Agent.new 'udp://localhost:8094' }
    let(:socket) { UDPSocket.new.tap {|s| s.bind 'localhost', 8094 } }

    it 'write points' do
      agent.write('demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1})
      expect(socket_read).to eq 'demo,a=1,b=2 a=1i,b=2.1'
    end
  end

  context 'with default' do
    let(:agent) { ::Telegraf::Agent.new 'udp://localhost:8094' }
    let(:socket) { UDPSocket.new.tap {|s| s.bind 'localhost', 8094 } }

    it 'writes points to UDP on localhost:8094' do
      agent.write('demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1})
      expect(socket_read).to eq 'demo,a=1,b=2 a=1i,b=2.1'
    end
  end
end
