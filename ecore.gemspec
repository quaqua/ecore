# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ecore/version"

Gem::Specification.new do |s|
  s.name        = "ecore"
  s.version     = Ecore::VERSION
  s.authors     = ["thorsten zerha"]
  s.email       = ["quaqua@tastenwerk.com"]
  s.homepage    = ""
  s.summary     = %q{ecore is a content repository mapper for RubyOnRails, ActiveRecord}
  s.description = %q{ecore is a content repository allowing you to deal with objects as nodes, having privileges and getting cross-linked to each other, regardless of it's kind}

  s.rubyforge_project = "ecore"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
   
  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options     = ["--main", "README.rdoc"]
  
  s.add_dependency "uuidtools"
  s.add_development_dependency "rspec"

end
