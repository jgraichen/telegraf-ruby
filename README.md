# Telegraf

Send events to a local [Telegraf](https://github.com/influxdata/telegraf) agent or anything that can receive the InfluxDB line protocol.

It further includes plugins for Rack and Rails to collect request events. See plugin usage details below.

This gem only uses the line protocol from the `influxdb` gem and does not depend on any specific version. This may break in the future but does not restrict you in using a your preferred `influxdb` gem version.

## Installation

```ruby
gem 'telegraf'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install telegraf

## Usage as a library

Configure telegraf socket listener e.g.:

```
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

There is not buffer or batch handling, nor connection pooling or keep alive. Each `#write` creates a new connection (unless it's a datagram connection).

There is no exception handling.

## Using the Rack and Rails plugins

This gem include a Rails plugin and a rack middleware to collect request events. They need to be explicitly required to be used:

### Rack

```
require "telegraf/rack"

agent = ::Telegraf::Agent.new
use ::Telegraf::Rack.new(series: 'rack', agent: agent, tags: {global: 'tag'})
```

See middleware [class documentation](lib/telegraf/rack.rb) for more details.

The Rack middleware supports parsing the `X-Request-Start: t=<timestamp>` header expecting a fractional (UTC) timestamp when the request has been started or first received by e.g. a load balancer. An additional value `queue_ms` with the queue time will be included.

### Rails

The Rails plugin needs to required too but by default automatically installs required components.

```
# e.g. in application.rb

require "telegraf/rails"

class MyApplication > ::Rails::Application
  # Configure receiver
  config.telegraf.connect = "udp://localhost:9084"

  # By default the Rack middleware to collect events is installed
  config.telegraf.rack.enabled = true
  config.telegraf.rack.series = "requests"
  config.telegraf.rack.tags = {}

  # Additionally the application is instrumented to tag events with
  # controller and action as well as to collect app, database and view timings
  config.telegraf.instrumenation = true
end
```

Received event example:

```
requests,action=index,controller=TestController,instance=TestController#index,method=GET,status=200 db_ms=0.0,view_ms=2.6217450003969134,action_ms=2.702335,app_ms=4.603561000294576,send_ms=0.09295000018028077,request_ms=4.699011000411701,queue_ms=0.00003000028323014
```

See the rack middleware [class documentation](lib/telegraf/rack.rb) and the Rails plugin [class documentation](lib/telegraf/railtie.rb) for more details on  the collected tags and values.

## License

Copyright (C) 2017-2020 Jan Graichen

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
