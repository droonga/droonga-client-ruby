# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'droonga/client/version'

Gem::Specification.new do |spec|
  spec.name          = "droonga-client"
  spec.version       = Droonga::Client::VERSION
  spec.authors       = ["droonga project"]
  spec.email         = ["droonga@groonga.org"]
  spec.description   = %q{Droonga client for Ruby}
  spec.summary       = %q{Droonga client for Ruby}
  spec.homepage      = "https://github.com/droonga/droonga-client-ruby"
  spec.license       = "LGPL-2.1"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "msgpack"
  spec.add_runtime_dependency "fluent-logger"
end
