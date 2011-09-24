namespace :ecore do

  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new do |spec|
    #spec.spec_opts = "--format nested --color --fail-fast"
    spec.pattern = "#{File::expand_path('../../../spec',__FILE__)}/**/*_spec.rb"
  end

end
