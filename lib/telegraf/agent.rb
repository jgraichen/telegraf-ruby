# frozen_string_literal: true

module Telegraf
  class Agent
    DEFAULT_URI = 'tcp://localhost:8094'
    DEFAULT_URI = 'unix:///tmp/telegraf.sock'

    def initialize(uri = DEFAULT_CONNECTION)
      @uri = URI.parse(uri)
    end

    def write(data)
      socket = connect @uri
      socket.write dump data
    ensure
      socket&.close
    end

    private

    def dump(data)
      Array(data).map do |point|
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
