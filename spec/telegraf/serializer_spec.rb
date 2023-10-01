# frozen_string_literal: true

require 'spec_helper'

require 'telegraf'

RSpec.describe Telegraf::Serializer do
  subject(:serializer) { Telegraf::Serializer.new }

  describe '#dump' do
    it 'escapes whitespace in series' do
      expect(
        serializer.dump({
          series: 'my series',
          values: {a: 1},
        }),
      ).to eq 'my\ series a=1i'
    end

    it 'replaces LF with space' do
      expect(
        serializer.dump({
          series: 'series',
          tags: {app: "no\nyes"},
          values: {a: 1},
        }),
      ).to eq 'series,app=no\\ yes a=1i'
    end

    it 'replaces TAB with space' do
      expect(
        serializer.dump({
          series: 'series',
          tags: {app: "no\tyes"},
          values: {a: 1},
        }),
      ).to eq 'series,app=no\\ yes a=1i'
    end

    it 'replaces CR with space' do
      expect(
        serializer.dump({
          series: 'series',
          tags: {app: "no\ryes"},
          values: {a: 1},
        }),
      ).to eq 'series,app=no\\ yes a=1i'
    end

    it 'replaces CRLF with space' do
      expect(
        serializer.dump({
          series: 'series',
          tags: {app: "no\r\nyes"},
          values: {a: 1},
        }),
      ).to eq 'series,app=no\\ yes a=1i'
    end

    it 'escapes quotes in field values' do
      expect(
        serializer.dump({
          series: 'series',
          values: {a: 'string "data"'},
        }),
      ).to eq 'series a="string \"data\""'
    end

    it 'strips invalid UTF-8 from series' do
      expect(
        serializer.dump({
          series: "series\xC9",
          values: {a: 1},
        }),
      ).to eq 'series a=1i'
    end

    it 'skips series with only invalid UTF-8' do
      expect(
        serializer.dump({
          series: "\xC9",
          values: {a: 1},
        }),
      ).to eq ''
    end

    it 'ignores nil value' do
      expect(
        serializer.dump({
          series: 'series',
          values: {a: 1, b: nil},
        }),
      ).to eq 'series a=1i'
    end

    it 'ignores nil values' do
      expect(
        serializer.dump({
          series: 'series',
          values: {a: nil},
        }),
      ).to eq ''
    end

    it 'ignores value name with invalid encoding' do
      expect(
        serializer.dump({
          series: 'series',
          values: {a: 1, '\xC9': nil},
        }),
      ).to eq 'series a=1i'
    end

    it 'ignores value names with invalid encoding' do
      expect(
        serializer.dump({
          series: 'series',
          values: {'\xC9': nil},
        }),
      ).to eq ''
    end

    it 'ignores nil tag' do
      expect(
        serializer.dump({
          series: 'series',
          tags: {a: 'test', b: nil},
          values: {a: 1},
        }),
      ).to eq 'series,a=test a=1i'
    end

    it 'ignores nil tags' do
      expect(
        serializer.dump({
          series: 'series',
          tags: {a: nil},
          values: {a: 1},
        }),
      ).to eq 'series a=1i'
    end

    it 'ignores NaN values' do
      expect(
        serializer.dump({
          series: 'series',
          values: {a: 1, b: 0 / 0.0},
        }),
      ).to eq 'series a=1i'
    end

    it 'ignores Infinity values' do
      expect(
        serializer.dump({
          series: 'series',
          values: {a: 1, b: 1 / 0.0},
        }),
      ).to eq 'series a=1i'
    end
  end
end
