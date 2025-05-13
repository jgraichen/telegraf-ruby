# frozen_string_literal: true

require 'bundler/setup'
require 'telegraf'

require 'socket'
require 'tmpdir'

module Support
  module Tmpdir
    extend RSpec::SharedContext

    attr_reader :tmpdir

    around do |example|
      Dir.mktmpdir do |dir|
        @tmpdir = dir
        example.run
      end
    end
  end

  module Socket
    extend RSpec::SharedContext

    Point = Struct.new(:series, :tags, :values, :timestamp) # rubocop:disable Lint/StructNewOverride

    let(:socket) { nil }
    let(:last_points) { socket_parse }
    let(:last_point) { last_points.first }

    around do |example|
      socket
      example.run
    ensure
      socket&.close
    end

    def socket_read
      if socket.respond_to?(:accept_nonblock)
        begin
          socket.accept_nonblock.read_nonblock(4096)
        rescue Errno::ENOTSUP # unixgram
          socket.read_nonblock(4096)
        end
      else
        socket.read_nonblock(4096)
      end
    end

    def socket_parse
      [].tap do |data|
        loop do
          socket_read.lines.each {|line| data << _parse(line) }
        rescue IO::EAGAINWaitReadable
          break
        end
      end
    end

    REGEXP = /^(?<series>\w+)(?:,(?<tags>.*))? (?<values>.*)(?<ts> \d+)?$/.freeze

    private

    def _parse(line)
      if (m = REGEXP.match(line))
        return Point.new(
          m['series'],
          _parse_fields(m['tags']),
          _parse_fields(m['values']),
          m['ts']&.strip&.to_i,
        )
      end

      raise "Cannot parse: #{line}"
    end

    def _parse_fields(str)
      return {} unless str

      str.split(',').to_h do |s|
        s.split('=')
      end
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Support::Tmpdir
  config.include Support::Socket

  # Use the GitHub Annotations formatter for CI
  if ENV['GITHUB_ACTIONS'] == 'true'
    require 'rspec/github'
    config.add_formatter RSpec::Github::Formatter
  end
end
