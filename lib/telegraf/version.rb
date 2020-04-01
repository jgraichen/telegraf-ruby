# frozen_string_literal: true

module Telegraf
  module VERSION
    MAJOR = 0
    MINOR = 6
    PATCH = 1
    STAGE = nil
    STRING = [MAJOR, MINOR, PATCH, STAGE].reject(&:nil?).join('.').freeze

    def self.to_s
      STRING
    end
  end
end
