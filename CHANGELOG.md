# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/jgraichen/telegraf-ruby/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/jgraichen/telegraf-ruby/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/jgraichen/telegraf-ruby/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/jgraichen/telegraf-ruby/compare/v0.8.0...v1.0.0
[0.8.0]: https://github.com/jgraichen/telegraf-ruby/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/jgraichen/telegraf-ruby/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/jgraichen/telegraf-ruby/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/jgraichen/telegraf-ruby/compare/v0.5.0...v0.6.0
