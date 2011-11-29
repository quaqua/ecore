require "bundler/gem_tasks"

namespace :ecore do
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new do |spec|
    #spec.spec_opts = "--format nested --color --fail-fast"
    spec.pattern = "#{File::expand_path('../spec',__FILE__)}/**/*_spec.rb"
  end

  #RSpec::Core::RakeTask.new(:rcov => spec_prereq) do |t|
  #  t.rcov = true
  #  t.pattern = "./spec/**/*_spec.rb"
  #  t.rcov_opts = '--exclude /gems/,/Library/,/usr/,lib/tasks,.bundle,config,/lib/rspec/,/lib/rspec-'
  #end

  require 'rcov/rcovtask'
  Rcov::RcovTask.new(:cov) do |cov|
    cov.test_files = FileList['spec/spec*.rb']
    cov.rcov_opts << '--exclude gem' << '--exclude spec_helper.rb' #%q[--exclude "gem"]
    # t.verbose = true     # uncomment to see the executed command
  end
  
  description = "ecore migration script to run before ecore:spec"
  desc description
  task :prepare_spec do
    require 'fileutils'
    require File::expand_path "../lib/ecore", __FILE__
    FileUtils::rm("./test.sqlite3") if File::exists?("./test.sqlite3")
    Ecore::Repository.init "spec/test-config-ecore.yml"
    Ecore::Document.migrate
    Ecore::Link.migrate
    Ecore::Label.migrate
    Ecore::User.migrate
    Ecore::Document.migrate
    Ecore::Audit.migrate
  end

end
