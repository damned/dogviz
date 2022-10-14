# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dogviz/version'

Gem::Specification.new do |spec|
  spec.name          = "dogviz"
  spec.version       = Dogviz::VERSION
  spec.authors       = ["damned"]
  spec.email         = ["writetodan@yahoo.com"]

  spec.summary       = %q{domain object graph visualisation}
  spec.description   = %q{leverages graphviz to generate multiple views of a domain-specific graph}
  spec.homepage      = "https://github.com/damned/dogviz"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.3.23"
  spec.add_development_dependency "rake", "~> 13.0.6"
  spec.add_development_dependency 'simplecov', '~> 0'
  spec.add_development_dependency 'colorize', '~> 0'
  spec.add_development_dependency 'nokogiri', '~> 1.6'
  spec.add_development_dependency 'test-unit'

  spec.add_dependency 'ruby-graphviz', '~> 1'
  spec.add_dependency 'json', '~> 2.3.0'
end
