module Ecore

  # raised, if anything goes wrong with the authentication process
  class AuthenticationError < StandardError
  end

  class MissingSession < StandardError
  end

  class Session
   
    attr_reader :user
    
    # Session.new(:email => 'user@email.com', :password => 'cleartextpassword')
    # or
    # Session.new(:name => 'name', :password => 'pass')
    # if authentication fails, a AuthenticationError will be thrown
    def initialize(options)
      options[:hashed_password] = Ecore::User.encrypt_password( options.delete(:password) ) if options[:password]
      ( @user = Ecore::User.anybody ; @user.session = self ; return ) if options[:name] == "anybody"
      raise AuthenticationError.new unless (validate_options( options ) and authenticate( options ))
    end
    
    # authenticates given user attributes against index file
    # at least name or email and password has to be given
    def authenticate(options)
      @user = Ecore::User.where(:name => options[:name], :hashed_password => options[:hashed_password]).first if options.has_key?(:name)
      @user = Ecore::User.where(:email => options[:email], :hashed_password => options[:hashed_password]).first if @user.nil? and options.has_key?(:email)
      return false if @user.nil?
      return false unless @user.is_a?(Ecore::User)
      @user.session = self
      true
    end
    
    # reloads a session and updates session's user attributes
    def reload
      @user = Ecore::User.where(:id => @user.id).first
    end
    
    private
    
    def validate_options( options )
      return false if !options.has_key?(:email) and !options.has_key?(:name)
      return false if options.has_key?(:email) and options[:email].empty?
      return false if options.has_key?(:name) and options[:name].empty?
      true
    end
    
  end
  
end
