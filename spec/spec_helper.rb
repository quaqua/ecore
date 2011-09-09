ENV['RAILS_ENV'] = 'test'
 
require 'test/unit'
require File.expand_path(File.join(Dir.pwd, 'config/environment.rb'))
 
def load_schema
  config = YAML::load(IO.read('config/database.yml'))
  ActiveRecord::Base.logger = Logger.new("log/test.log")
 
  db_adapter = ENV['DB']
 
  # no db passed, try one of these fine config-free DBs before bombing.
  db_adapter ||=
    begin
      require 'rubygems'
      require 'sqlite'
      'sqlite'
    rescue MissingSourceFile
      begin
        require 'sqlite3'
        'sqlite3'
      rescue MissingSourceFile
      end
    end
 
  if db_adapter.nil?
    raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."
  end
 
  ActiveRecord::Base.establish_connection(config[db_adapter])
  load("db/schema.rb") if !File::exists?('db/test.sqlite3')
  require File.dirname(__FILE__) + '/../init'
end

def create_folder(name)
  Folder.create!(:name => name, :session => @session)
end

require 'rspec'
require 'rspec/autorun'
require File::expand_path('../../app/models/folder',__FILE__)

load_schema
