require 'logger'
require 'sequel'

module Ecore

  # shortcut for Config class providing access to the
  # Ecore environment variables
  def self.env
    Config
  end

  # can be used to log to given log file
  def self.logger
    LoggerMapper.current
  end

  # main database conneciton
  def self.db
    DBMapper.connection
  end

  # setup error is raised if
  # anything goes wrong during the configuration
  # process
  class ConfigError < StandardError
  end

  # the Config class holds configuration settings
  # for ecore. It can also be used from extern by:
  #   Ecore::env.get(:key_name)
  # or
  #   Ecore::env.set(:key_name, value)
  # whereas a value can by any ruby object. It will be stored
  # in a simple hash and is not persistant
  class Config

    # get the value of a specified key. Will return
    # nil if key was not found
    def self.get(key)
      @env ||= {}
      @env[key]
    end

    # set the value of a key. It will override existing
    # key values at any level
    def self.set(key,value)
      @env ||= {}
      if value.is_a?(Hash)
        newval = {}
        value.each_pair do |k,v|
          newval[k.to_sym] = v
        end
        @env[key] = newval
      else
        @env[key] = value
      end
    end

  end

  class LoggerMapper

    def self.current
      unless @logger
        @logger = Logger.new((Ecore::env.get(:logger)[:file] || $stdout))
        @logger.level = (Ecore::env.get(:logger)[:level] ? eval("Logger::#{Ecore::env.get(:logger)[:level].upcase}") : Logger::INFO)
      end
      @logger
    end

  end

  class DBMapper

    # connect to the database
    # this is configured in the ecore.yml (or other if specified at Ecore::Repository.init)
    #
    # options in ecore.yml:
    #
    # default options for sqlite3
    #   db:
    #     adapter: 'sqlite3' # default
    #     database: 'db/mydb.sqlite3'
    #
    # typical options for mysql
    #   db:
    #     adapter: 'mysql'
    #     database: 'mydb'
    #     user: 'user'
    #     password: 'userpwd'
    #     host: 'localhost'
    #
    # typical options for jdbc:sqlite
    #   db:
    #     adapter: 'jdbc'
    #     database: 'jdbc:sqlite:db/mydb.sqlite3'
    #
    def self.connection
      unless @db
        @connection_settings = {:adapter => 'sqlite', :database => 'db/ecore.sqlite3'}
        if Ecore::env.get(:db) && Ecore::env.get(:db)[:adapter] && Ecore::env.get(:db)[:adapter] != "sqlite"
          if Ecore::env.get(:db)[:adapter] == "jdbc"
            @connection_settings = Ecore::env.get(:db)[:database]
          else
            @connection_settings = { :adapter => Ecore::env.get(:db)[:adapter],
              :host => Ecore::env.get(:db)[:host],
              :user => Ecore::env.get(:db)[:user],
              :password => Ecore::env.get(:db)[:password],
              :encoding => (Ecore::env.get(:db)[:encoding] || 'utf8')}
          end
        end
        if Ecore::env.get(:db) && Ecore::env.get(:db)[:database]
          if Ecore::env.get(:db)[:adapter] && Ecore::env.get(:db)[:adapter] == 'jdbc'
            @db = Sequel.connect(@connection_settings, :logger => Ecore::logger)
          else
            @connection_settings.merge!(:database => Ecore::env.get(:db)[:database]) 
            @connection_settings.merge!(:logger => Ecore::logger)
            @db = Sequel.connect(@connection_settings)
          end
        else
          @db = Sequel.connect(@connection_settings)
        end
      end
      @db
    rescue Sequel::DatabaseDisconnectError
      @db = Sequel.connect(@connection_settings)
    end

  end

  module Repository

    # initializes ecore, reads configuration settings from
    # given configuration file (or defaults to config/ecore.yml)
    #
    # A sample ecore.yml file can be found on /ecore.yml.example
    # options
    #
    # * <tt>config_file</tt> - the configuration file that should be used for this ecore session
    #
    def self.init(config_file=File.join("config","ecore.yml"))
      require 'yaml'
      raise ConfigError.new("'#{config_file}' could not be found") unless ::File::exists?(config_file)
      tmpenv = YAML::load( ::File::open( config_file ) )
      tmpenv.each_pair do |key,value|
        Ecore::env.set key.to_sym, value
      end
      Ecore::logger.info("ecore initialized.")
      #Ecore::Blob.default_fs_path = Ecore::env.get(:default_fs_path) || File::join('db','ecore_datastore')
    end

    # migrates all necessary tables to run ecore
    def self.migrate
      Ecore::Document.migrate
      Ecore::Link.migrate
      Ecore::Label.migrate
      Ecore::User.migrate
      Ecore::Audit.migrate
    end


  end
end
