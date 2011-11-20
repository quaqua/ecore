# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ecore/version"

Gem::Specification.new do |s|
  s.name        = "ecore"
  s.version     = Ecore::VERSION
  s.authors     = ["thorsten zerha"]
  s.email       = ["quaqua@tastenwerk.com"]
  s.homepage    = ""
  s.summary     = %q{a document (content) repository based on SQL written in ruby}
  s.description = %q{a document repository using SQL written in ruby}

  s.rubyforge_project = "ecore"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "rcov"
  s.add_dependency "activesupport"
  s.add_dependency "sequel"

  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options     = ["--main", "README.rdoc"]
  
end
