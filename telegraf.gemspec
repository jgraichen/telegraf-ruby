# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'telegraf/version'

Gem::Specification.new do |spec|
  spec.name          = 'telegraf'
  spec.version       = Telegraf::VERSION
  spec.authors       = ['Jan Graichen']
  spec.email         = ['jgraichen@altimos.de']

  spec.summary       = 'Metric Reporter to local telegraf agent'
  spec.description   = 'Metric Reporter to local telegraf agent'
  spec.homepage      = 'https://github.com/jgraichen/telegraf-ruby'
  spec.license       = 'LGPLv3'

  spec.metadata = {
    'rubygems_mfa_required' => 'true',
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'bigdecimal'
end
