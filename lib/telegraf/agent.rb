# frozen_string_literal: true

module Telegraf
  class Agent
    DEFAULT_CONNECTION = 'udp://localhost:8094'

    attr_reader :uri, :logger

    def initialize(uri = nil, logger: nil)
      @uri = URI.parse(uri || DEFAULT_CONNECTION)
      @logger = logger
    end

    def write(*args, **kwargs)
      write!(*args, **kwargs)
    rescue StandardError => e
      logger&.error('telegraf') do
        e.to_s + e.backtrace.join("\n")
      end
    end

    def write!(data, series: nil, tags: nil, values: nil)
      if values
        data = [{series: series || data.to_s, tags: tags, values: values}]
      end

      socket = connect @uri
      socket.write dump data
    ensure
      socket&.close
    end

    private

    def dump(data)
      data.each.map do |point|
        ::InfluxDB::PointValue.new(point).dump
      end.join("\n")
    end

    def connect(uri)
      case uri.scheme.downcase
        when 'unix'
          Socket.new(:UNIX, :STREAM).tap do |socket|
            socket.connect(Socket.pack_sockaddr_un(uri.path))
          end
        when 'unixgram'
          Socket.new(:UNIX, :DGRAM).tap do |socket|
            socket.connect(Socket.pack_sockaddr_un(uri.path))
          end
        when 'tcp', 'tcp4', 'tcp6'
          TCPSocket.new uri.host, uri.port
        when 'udp', 'udp4', 'udp6'
          UDPSocket.new.tap do |socket|
            socket.connect uri.host, uri.port
          end
        else
          raise "Unknown connection type: #{uri.scheme}"
      end
    end
  end
end
