<!-- markdownlint-disable-file MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [3.3.0] - 2025-06-14

### Added

- Support for integer timestamps in X-Request-Start by @leshik (#37)

## [3.2.0] - 2025-03-08

### Added

- Support for Sidekiq 8

## [3.1.0] - 2025-01-31

### Added

- Support for Ruby 3.4, Rails 8.0, Rack 3

## [3.0.0] - 2024-03-11

### Added

- New standalone Influx line protocol serializer
- `before_send` filter option for agent and all plugins (#27)

### Changed

- Require Ruby 2.7+

## [2.1.1] - 2022-08-23

### Fixed

- Possible RuntimeError: can't add a new key into hash during iteration (@MrSerth)

## [2.1.0] - 2022-01-24

### Added

- Support for Rails 7.0 and Ruby 3.1
- Grape API instrumentation (#17)

## [2.0.0] - 2021-09-30

### Changed

- The sidekiq middleware does not use keyword arguments as sidekiq does not handle them correctly on Ruby 3.0 (#14)

## [1.0.0] - 2021-01-26

### Added

- Global tags (#6)

## [0.8.0] - 2020-12-02

### Added

- ActiveJob instrumentation (#10)

## [0.7.0] - 2020-05-07

### Added

- Sidekiq middleware (#8)

## [0.6.1] - 2020-04-01

### Fixed

- Fix type in instrumentation option (#7)

## [0.6.0] - 2020-03-31

### Added

- New Rack middleware and Rails plugin to collect request events (#5)

## 0.5.0 - undefined

### Changed

- Remove `influxdb` not unnecessarily restrict users needing a specific influxdb client.

[Unreleased]: https://github.com/jgraichen/telegraf-ruby/compare/v3.3.0...HEAD
[3.3.0]: https://github.com/jgraichen/telegraf-ruby/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/jgraichen/telegraf-ruby/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/jgraichen/telegraf-ruby/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/jgraichen/telegraf-ruby/compare/v2.1.1...v3.0.0
[2.1.1]: https://github.com/jgraichen/telegraf-ruby/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/jgraichen/telegraf-ruby/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/jgraichen/telegraf-ruby/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/jgraichen/telegraf-ruby/compare/v0.8.0...v1.0.0
[0.8.0]: https://github.com/jgraichen/telegraf-ruby/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/jgraichen/telegraf-ruby/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/jgraichen/telegraf-ruby/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/jgraichen/telegraf-ruby/compare/v0.5.0...v0.6.0
