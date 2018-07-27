# frozen_string_literal: true

module Telegraf
  module VERSION
    MAJOR = 0
    MINOR = 5
    PATCH = 0
    STAGE = nil
    STRING = [MAJOR, MINOR, PATCH, STAGE].reject(&:nil?).join('.').freeze

    def self.to_s
      STRING
    end
  end
end
