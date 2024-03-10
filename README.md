# Telegraf

[![Gem Version](https://img.shields.io/gem/v/telegraf?logo=ruby)](https://rubygems.org/gems/telegraf)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jgraichen/telegraf-ruby/test.yml?logo=github)](https://github.com/jgraichen/telegraf-ruby/actions)

Send events to a local [Telegraf](https://github.com/influxdata/telegraf) agent or anything that can receive the InfluxDB line protocol.

It further includes plugins for Rack, Rails, ActiveJob and Sidekiq to collect request events. See plugin usage details below.

## Installation

```ruby
gem 'telegraf'
```

And then execute:

```console
bundle
```

Or install it yourself as:

```ruby
gem install telegraf
```

## Usage as a library

Configure telegraf socket listener e.g.:

```toml
[[inputs.socket_listener]]
  service_address = "udp://localhost:8094"
```

```ruby
telegraf = Telegraf::Agent.new 'udp://localhost:8094'
telegraf = Telegraf::Agent.new # default: 'udp://localhost:8094'

telegraf.write('demo',
    tags: {tag_a: 'A', tag_b: 'B'},
    values: {value_a: 1, value_b: 1.5})

telegraf.write([{
    series: 'demo',
    tags: {tag_a: 'A', tag_b: 'B'},
    values: {value_a: 1, value_b: 1.5}
}])
```

There is no buffer or batch handling, nor connection pooling or keep alive. Each `#write` creates a new connection (unless it's a datagram connection).

There is no exception handling.

## Using the Rack and Rails plugins

This gem includes a Rails plugin and middlewares / adapters for Rack, ActiveJob and Sidekiq, to collect request and background worker events. You need to require them explicitly:

### Rack

```ruby
require "telegraf/rack"

agent = ::Telegraf::Agent.new
use ::Telegraf::Rack.new(series: 'rack', agent: agent, tags: {global: 'tag'})
```

See middleware [class documentation](lib/telegraf/rack.rb) for more details.

The Rack middleware supports parsing the `X-Request-Start: t=<timestamp>` header expecting a fractional (UTC) timestamp when the request has been started or first received by e.g. a load balancer. An additional value `queue_ms` with the queue time will be included.

### Rails

The Rails plugin needs to be required, too, but will automatically install additional components (Rack, ActiveJob, Sidekiq and Rails-specific instrumentation).

```ruby
# e.g. in application.rb

# Load rails plugin (!) or add `require: 'telegraf/rails'` to Gemfile
require "telegraf/rails"

class MyApplication > ::Rails::Application
  # Configure receiver
  config.telegraf.connect = "udp://localhost:8094"

  # Global tags added to all events. These will override
  # any local tag with the same name.
  config.telegraf.tags = {}

  # By default the Rack middleware to collect events is installed
  config.telegraf.rack.enabled = true
  config.telegraf.rack.series = "requests"
  config.telegraf.rack.tags = {}

  # These are the default settings when ActiveJob is detected
  config.telegraf.active_job.enabled = true
  config.telegraf.active_job.series = "active_job"
  config.telegraf.active_job.tags = {}

  # These are the default settings when Sidekiq is detected
  config.telegraf.sidekiq.enabled = true
  config.telegraf.sidekiq.series = "sidekiq"
  config.telegraf.sidekiq.tags = {}

  # Additionally the application is instrumented to tag events with
  # controller and action as well as to collect app, database and view timings
  config.telegraf.instrumentation = true
end
```

Received event example:

```text
requests,action=index,controller=TestController,instance=TestController#index,method=GET,status=200 db_ms=0.0,view_ms=2.6217450003969134,action_ms=2.702335,app_ms=4.603561000294576,send_ms=0.09295000018028077,request_ms=4.699011000411701,queue_ms=0.00003000028323014
```

See the various classes' documentation for more details on the collected tags and values:

- [Rack middleware](lib/telegraf/rack.rb)
- [Rails plugin](lib/telegraf/railtie.rb)
- [ActiveJob plugin](lib/telegraf/active_job.rb)
- [Sidekiq middleware](lib/telegraf/sidekiq.rb)

### ActiveJob

```ruby
require "telegraf/active_job"

agent = ::Telegraf::Agent.new
ActiveSupport::Notifications.subscribe(
  'perform.active_job',
  Telegraf::ActiveJob.new(agent: agent, series: 'active_job', tags: {global: 'tag'})
)
```

See plugin [class documentation](lib/telegraf/active_job.rb) for more details.

### Sidekiq

```ruby
require "telegraf/sidekiq"

agent = ::Telegraf::Agent.new
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add ::Telegraf::Sidekiq::Middleware, agent, series: 'sidekiq', tags: {global: 'tag'}
  end
end
```

See middleware [class documentation](lib/telegraf/sidekiq.rb) for more details.

## License

Copyright (C) 2017-2024 Jan Graichen

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
