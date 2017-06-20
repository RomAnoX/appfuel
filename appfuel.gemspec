# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'appfuel/version'

Gem::Specification.new do |spec|
  spec.name          = "appfuel"
  spec.version       = Appfuel::VERSION
  spec.authors       = ["Robert Scott-Buccleuch"]
  spec.email         = ["rsb.code@gmail.com"]

  spec.summary       = %q{Appfuel decouples your business code from its API framework}
  spec.description   = %q{A library that allows you to isolate your business code}
  spec.homepage      = "https://github.com/rsb/appfuel"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # we have to lock dry-types due to failures I am encountering
  # when dynamically creating form validators. Not sure if it is the library
  # or the way I am using it.
  spec.add_dependency "activerecord",     "~> 5.1.0"
  spec.add_dependency "pg",               "~> 0.20"
  spec.add_dependency "dry-types",        "0.9.2"
  spec.add_dependency "dry-container",    "~> 0.6"
  spec.add_dependency "dry-validation",   "~> 0.10.5"
  spec.add_dependency "dry-monads",       "~> 0.2"
  spec.add_dependency "dry-configurable", "~> 0.6"
  spec.add_dependency "parslet",          "~> 1.8.0"
  spec.add_dependency "rest-client",      "~> 2.0"

  spec.add_development_dependency "bundler",            "~> 1.13"
  spec.add_development_dependency "rake",               "~> 10.0"
  spec.add_development_dependency "rspec",              "~> 3.5"
  spec.add_development_dependency "pry",                "~> 0.10"
  spec.add_development_dependency "awesome_print",      "~> 1.7"
  spec.add_development_dependency "pry-awesome_print",  ">= 9.6.1"
  spec.add_development_dependency "database_cleaner",   "~> 1.5"
  spec.add_development_dependency "faker",              "~> 1.7"
  spec.add_development_dependency "factory_girl",       "~> 4.8"
end
