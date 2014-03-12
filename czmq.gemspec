# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'czmq/version'

Gem::Specification.new do |spec|
  spec.name          = 'czmq'
  spec.version       = CZMQ::VERSION
  spec.authors       = ['Mauro Tortonesi']
  spec.email         = ['mauro.tortonesi@unife.it']
  spec.description   = %q{Ruby bindings for CZMQ}
  spec.summary       = %q{Ruby gem that provides bindings for the CZMQ library.
    This is a pure Ruby gem that interfaces with CZMQ using FFI, so it
    should work under MRI, JRuby, and Rubinius.}
  spec.homepage      = 'https://github.com/mtortonesi/ruby-czmq'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'czmq-ffi'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
