# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegraf do
  it 'has a version number' do
    expect(Telegraf::VERSION).not_to be nil
  end

  it 'UNIX socket (I)' do
    Dir.mktmpdir do |dir|
      server = UNIXServer.new "#{dir}/telegraf.sock"
      agent  = Telegraf::Agent.new "unix:#{dir}/telegraf.sock"

      agent.write([
                    {series: 'demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1}},
                    {series: 'demo', tags: {a: '1', b: 2}, values: {a: 6, b: 2.5}}
                  ])

      recv = server.accept.read_nonblock(4096)

      expect(recv).to eq "demo,a=1,b=2 a=1i,b=2.1\ndemo,a=1,b=2 a=6i,b=2.5"

      server.close
    end
  end

  it 'UNIX socket (II)' do
    Dir.mktmpdir do |dir|
      server = UNIXServer.new "#{dir}/telegraf.sock"
      agent  = Telegraf::Agent.new "unix:#{dir}/telegraf.sock"

      agent.write('demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1})

      recv = server.accept.read_nonblock(4096)

      expect(recv).to eq "demo,a=1,b=2 a=1i,b=2.1"

      server.close
    end
  end

  it 'UNIXGRAM socket' do
    Dir.mktmpdir do |dir|
      server = Socket.new(:UNIX, :DGRAM).tap do |socket|
        socket.bind Socket.pack_sockaddr_un "#{dir}/telegraf.sock"
      end

      agent = Telegraf::Agent.new "unixgram:#{dir}/telegraf.sock"

      agent.write([
                    {series: 'demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1}},
                    {series: 'demo', tags: {a: '1', b: 2}, values: {a: 6, b: 2.5}}
                  ])

      recv = server.read_nonblock(4096)

      expect(recv).to eq "demo,a=1,b=2 a=1i,b=2.1\ndemo,a=1,b=2 a=6i,b=2.5"

      server.close
    end
  end

  it 'TCP socket' do
    Dir.mktmpdir do |_dir|
      server = TCPServer.new 'localhost', 8094
      agent  = Telegraf::Agent.new 'tcp://localhost:8094'

      agent.write([
                    {series: 'demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1}},
                    {series: 'demo', tags: {a: '1', b: 2}, values: {a: 6, b: 2.5}}
                  ])

      recv = server.accept.read_nonblock(4096)

      expect(recv).to eq "demo,a=1,b=2 a=1i,b=2.1\ndemo,a=1,b=2 a=6i,b=2.5"

      server.close
    end
  end

  it 'UDP socket' do
    Dir.mktmpdir do |_dir|
      server = UDPSocket.new
      server.bind 'localhost', 8094

      agent = Telegraf::Agent.new 'udp://localhost:8094'

      agent.write([
                    {series: 'demo', tags: {a: 1, b: 2}, values: {a: 1, b: 2.1}},
                    {series: 'demo', tags: {a: '1', b: 2}, values: {a: 6, b: 2.5}}
                  ])

      recv = server.read_nonblock(4096)

      expect(recv).to eq "demo,a=1,b=2 a=1i,b=2.1\ndemo,a=1,b=2 a=6i,b=2.5"

      server.close
    end
  end
end
