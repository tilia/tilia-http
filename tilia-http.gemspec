require File.join(File.dirname(__FILE__), 'lib', 'tilia', 'http', 'version')
Gem::Specification.new do |s|
  s.name        = 'tilia-http'
  s.version     = Tilia::Http::Version::VERSION
  s.licenses    = ['BSD-3-Clause']
  s.summary     = 'Port of the sabre-http library to ruby'
  s.description = "Port of the sabre-http library to ruby.\n\nThe tilia_http library provides utilities for dealing with http requests and responses."
  s.author      = 'Jakob Sack'
  s.email       = 'tilia@jakobsack.de'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/tilia/tilia-http'
  s.required_ruby_version = '>= 2.7.0'
  s.add_runtime_dependency 'activesupport', '>= 4.0'
  s.add_runtime_dependency 'typhoeus', '~> 1.4'
  s.add_runtime_dependency 'rchardet', '~>1.6'
  s.add_runtime_dependency 'tilia-event', '~> 2.0'
  s.add_runtime_dependency 'tilia-uri', '~> 1.0'
  s.add_runtime_dependency 'rack', '>= 1.6'
end
