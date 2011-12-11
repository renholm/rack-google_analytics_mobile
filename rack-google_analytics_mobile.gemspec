# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "rack-google_analytics_mobile"
  s.version     = '0.0.1'
  s.authors     = ["renholm"]
  s.email       = ["kristoffer@renholm.se"]
  s.homepage    = ""
  s.summary     = %q{Adds Google Analytics Mobile tracking to pages}

  s.rubyforge_project = "rack-google_analytics_mobile"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "addressable"
end
