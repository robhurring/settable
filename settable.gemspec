# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'settable'

Gem::Specification.new do |gem|
  gem.name          = 'settable'
  gem.version       = Settable::VERSION
  gem.authors       = ['Rob Hurring']
  gem.email         = ['robhurring@gmail.com']
  gem.summary       = %q{Small include to make config files better}
  gem.description   = %q{Small include to make config files better}
  gem.homepage      = 'https://github.com/robhurring/settable'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency 'rspec'
end
