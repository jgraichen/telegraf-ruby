# frozen_string_literal: true

module Telegraf
  module VERSION
    MAJOR = 2
    MINOR = 1
    PATCH = 0
    STAGE = nil
    STRING = [MAJOR, MINOR, PATCH, STAGE].compact.join('.').freeze

    def self.to_s
      STRING
    end
  end
end
