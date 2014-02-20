# -*- coding: utf-8 -*-
#
# Copyright (C) 2013-2014 Droonga Project
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'droonga/client/version'

Gem::Specification.new do |spec|
  spec.name          = "droonga-client"
  spec.version       = Droonga::Client::VERSION
  spec.authors       = ["Droonga Project"]
  spec.email         = ["droonga@groonga.org"]
  spec.description   = %q{Droonga client for Ruby}
  spec.summary       = %q{Droonga client for Ruby}
  spec.homepage      = "https://github.com/droonga/droonga-client-ruby"
  spec.license       = "LGPL-2.1"
  spec.required_ruby_version = '>= 1.9.3'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "msgpack"
  spec.add_runtime_dependency "fluent-logger"
  spec.add_runtime_dependency "rack"
  spec.add_runtime_dependency "yajl-ruby"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "packnga"
end
