# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "settable"

Gem::Specification.new do |s|
  s.name        = "settable"
  s.version     = Settable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Rob Hurring"]
  s.email       = ["robhurring@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Small include to make config files better}
  s.description = %q{Small include to make config files better}

  s.rubyforge_project = "settable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
