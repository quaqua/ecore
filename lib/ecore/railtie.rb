# initializes ecore inside
# the Rails framework

module Ecore
  class Railtie < Rails::Railtie

    initializer "ecore.initialize" do |app|
      require File::expand_path('../init',__FILE__)
      require File::expand_path('../../../app/models/ecore/audit_log', __FILE__ )
      require File::expand_path('../../../app/models/ecore/group', __FILE__ )
      require File::expand_path('../../../app/models/ecore/user', __FILE__ )
      require File::expand_path('../../../app/models/folder', __FILE__ )
    end

    rake_tasks do
      load File::expand_path('../../tasks/test.rake', __FILE__) if ENV['RAILS_ENV'] == 'development'
      load File::expand_path('../../tasks/migrate.rake', __FILE__)
    end

  end
end
