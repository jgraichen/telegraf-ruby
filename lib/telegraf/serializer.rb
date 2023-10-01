# frozen_string_literal: true

module Telegraf
  class Serializer
    QUOTE_SERIES = /[ ,]/.freeze
    QUOTE_TAG_KEY = /[ ,=]/.freeze
    QUOTE_TAG_VALUE = /[ ,=]/.freeze
    QUOTE_FIELD_KEY = /[ ,="]/.freeze
    QUOTE_FIELD_VALUE = /[\\"]/.freeze
    QUOTE_REPLACE = /[\t\r\n]+/.freeze

    def dump_all(points)
      points
        .each
        .filter_map {|point| dump(point) }
        .join("\n")
    end

    def dump(point)
      series = quote(point[:series], QUOTE_SERIES)
      return '' if series.empty?

      values = point.fetch(:values).filter_map do |key, value|
        k = quote(key.to_s, QUOTE_FIELD_KEY)
        v = encode_value(value)
        next if k.empty? || v.nil?

        "#{k}=#{v}"
      end
      return '' if values.empty?

      tags = point[:tags]&.filter_map do |key, value|
        k = quote(key.to_s, QUOTE_TAG_KEY)
        v = quote(value.to_s, QUOTE_TAG_VALUE)
        next if k.empty? || v.empty?

        "#{k}=#{v}"
      end

      StringIO.new.tap do |io|
        io << series
        io << ',' << tags.sort.join(',') if !tags.nil? && tags.any?
        io << ' ' << values.sort.join(',')
      end.string
    end

    private

    def encode_value(val)
      if val.nil?
        nil
      elsif val.is_a?(Integer)
        "#{val}i"
      elsif val.is_a?(Numeric)
        if val.nan? || val.infinite?
          nil
        else
          val.to_s
        end
      else
        "\"#{quote(val.to_s, QUOTE_FIELD_VALUE)}\""
      end
    end

    def quote(str, rule)
      str
        .encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '')
        .gsub(QUOTE_REPLACE, ' ')
        .gsub(rule) {|c| "\\#{c}" }
    end
  end
end
