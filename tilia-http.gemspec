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
  s.required_ruby_version = '>= 3.1.0'

  s.add_dependency 'activesupport', '>= 6.0'
  s.add_dependency 'rack', '>= 2.0'
  s.add_dependency 'rchardet', '>= 1.8'
  s.add_dependency 'tilia-event', '~> 2.0', '>= 2.0.2.2'
  s.add_dependency 'tilia-uri', '~> 1.0', '>= 1.0.1.3'
  s.add_dependency 'typhoeus', '~> 1.4'
end
