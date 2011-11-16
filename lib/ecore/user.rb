require 'digest/sha2'
require 'active_model' if defined?(Rails)
require File::expand_path("../attribute_methods", __FILE__)
require File::expand_path("../hooks", __FILE__)
require File::expand_path("../validations", __FILE__)
require File::expand_path("../active_model_layer", __FILE__)
require File::expand_path("../unique_id_generator", __FILE__)

module Ecore
  class User

    extend Ecore::AttributeMethods
    extend Ecore::UniqueIDGenerator
    extend Ecore::Hooks::ClassMethods
    extend Ecore::Validations::ClassMethods
    include Ecore::ActiveModelLayer
    include Ecore::Validations::InstanceMethods
    include Ecore::Hooks::InstanceMethods

    extend ActiveModel::Naming if defined?(Rails)

    attribute  :id, :string, :size => 8, :primary_key => true
    attribute  :name, :string, :null => false, :unique => true
    attribute  :group, :boolean, :default => false
    attribute  :personal_color, :string
    attribute  :photo_path, :string
    attribute  :email, :string
    attribute  :hashed_password, :string
    attribute  :updated_at, :datetime
    attribute  :created_at, :datetime
    attribute  :fullname, :string
    attribute  :group_ids, :string, :default => ""
    attribute  :role, :string
    attribute  :suspended, :boolean
    attribute  :last_login_at, :datetime
    attribute  :last_login_ip, :string
    attribute  :last_request_at, :datetime
    attribute  :confirmation_key, :string
    attribute  :default_locale, :string, :default => "en"

    def self.table_name
      :users
    end

    # Creates the users table
    # if not present.
    #
    def self.migrate
      attrs = @db_setup_attributes || {}
      Ecore::db.create_table :users do
        attrs.each_pair do |name, arr|
          column name, arr[0], arr[1]
        end
        index   :name
        index   :email
      end unless Ecore::db.table_exists?(:users)
    end

    # Encrypts the given password with the system's default password
    # encryption
    #
    # * <tt>password</tt> - The clear text password to be encrypted
    #
    def self.encrypt_password(password)
      Digest::SHA512.hexdigest(password)
    end

    # Returns the anybody user with limited privileges
    #
    def self.anybody
      new(nil, :name => "anybody")
    end

    # Returns the id of the anybody user
    def self.anybody_id
      "AAAAAAAA"
    end

    # Returns the number of (real) users in the
    # repository
    def self.count
      Ecore::db[:users].filter(:group => false).count
    end

    # Creates a new user in the repository.
    # This method is just calling new and save in serial order
    def self.create(user_id_or_user, attrs)
      u = new(user_id_or_user, attrs)
      u if u.save
    end

    # Creates a new user in the repository and throws an error if
    # anything goes wrong with the creation / saving process
    def self.create!(user_id_or_user, attrs)
      user = new(user_id_or_user,attrs)
      raise(SavingFailed, user.errors) unless user.save
      user
    end

    # Prepares a find dataset returning an empty dataset
    # with a :user table selector
    def self.find(user_id_or_user, options={})
      user_id = user_id_or_user.is_a?(String) ? user_id_or_user : user_id_or_user.id
      Ecore::db[:users].store_preconditions(user_id,nil,nil,options)
    end

    # finds a user by user_id
    #
    # * <tt>user_id</tt> - the user id of the user to find in the repository
    #
    def self.first(user_id)
      return anybody if user_id == anybody_id
      user_hash = Ecore::db[:users].first(:id => user_id) if user_id.is_a?(String)
      if user_id.is_a?(Hash)
        user_id.merge(:hashed_password => encrypt_password(user_id.delete(:password))) if user_id.has_key?(:password)
        user_hash = Ecore::db[:users].first(user_id)      
        user_id = nil
      end
      new(user_id, user_hash) if user_hash
    end

    attr_accessor :attributes, :password, :skip_audit, :send_confirmation

    validate :password_required_on_create
    validate :presence, :name
    validate :unique_name
    before :save, :encrypt_password
    before :create, :setup_default_role

    # Initialize a new User object
    #
    # examples:
    #   Ecore::User.new(user_id, :name => 'user1')
    #   # => <Ecore::User @name => 'user1'>
    #
    def initialize(user_id_or_user,attrs={})
      if attrs[:name] && attrs[:name] == 'anybody'
        @id = Ecore::User.anybody_id 
      elsif user_id_or_user
        @user_id = user_id_or_user.is_a?(String) ? user_id_or_user : user_id_or_user.id
      end
      set_attributes(attrs)
      @user_id = @id unless @user_id
      @changed_attributes = nil
    end

    def save
      return false unless run_validations
      this_new_record = new_record?
      success = false
      if this_new_record
        run_hooks(:before,:create) if this_new_record
        run_hooks(:before,:save)
        @id = self.class.gen_unique_id(:users)
        @created_at = Time.now
        @updated_at = Time.now
        Ecore::db[:users].insert(attributes.merge(:id => @id, :group => (self.class == Ecore::Group)))
        @changed_attributes = nil
        Ecore::Audit.log(@id, self.class.name, @name, "created", @user_id)
        success = true
      else # if not new record
        run_hooks(:before,:update)
        run_hooks(:before,:save)
        save_attrs = attributes
        save_attrs.delete(:created_at)
        save_attrs.delete(:type)
        save_attrs.delete(:id)
        @updated_at = Time.now
        Ecore::db[:users].where(:id => @id).update(save_attrs)
        Ecore::Audit.log(@id, self.class.name, @name, "updated", @user_id, @changed_attributes.inspect) unless @skip_audit
        @changed_attributes = nil
        success = true
      end 
      return false unless success
      run_hooks(:after,:create) if this_new_record
      run_hooks(:after,:update) unless this_new_record
      run_hooks(:after,:save)
      true
    end

    # Updates attributes of current user
    # and saves them to the repository
    #
    # example:
    #   user.update(:fullname => 'f1')
    #   # => true
    def update(attrs)
      #return false unless (@user_id == @id || Ecore::User.first(@user_id).is_admin?)
      attrs.each_pair do |key, value|
        send("#{key}=",value)
      end
      save
    end

    # Removes this user from the repository.
    # This action cannot be undone.
    def destroy
      return true if Ecore::db[:users].filter(:id => @id).delete
      false
    end

    # Reloads attributes from database
    def reload
      set_attributes(Ecore::db[:users].first(:id => @id))
      self
    end

    # Return all group_ids including own user_id
    def id_and_group_ids
      ((@group_ids && !@group_ids.empty?) ? "#{@id},#{@group_ids}" : @id)
    end

    # Returns true, if the given user is currently online
    def online?
      return false unless (Ecore::env.get(:users) && Ecore::env.get(:users)[:session_timeout_minutes])
      return true if (last_request_at && last_request_at > (Time.now - Ecore::env.get(:users)[:session_timeout_minutes] * 60))
      false
    end

    # Returns true, if user's roles include "manager"
    def is_admin?
      @role.include? "manager"
    end

    # Returns true, if user's roles include "editor"
    def is_editor?
      @role.include? "editor"
    end

    # Returns true, if user has been suspended
    def suspended?
      @suspended
    end

    # Returns fullname, if set, otherwise name
    def fullname_or_name
      ((fullname && !fullname.empty?) ? fullname : name)
    end

    # Adds a group to this user
    # the group_id is allways stored within this
    # user object
    # the user object is not saved after this method call
    # returns true if the group could be added successfully
    #
    # * <tt>group</tt> - The group object to be added to this user
    #
    def add_group( group )
      raise TypeError.new('not a group') unless group.is_a?(Ecore::Group)
      tmp_group_ids = self.group_ids.split(',')
      tmp_group_ids.delete(group.id)
      tmp_group_ids << group.id
      self.group_ids = tmp_group_ids.join(',')
      true
    end

    # Adds a group to this user object
    # and stores the user object
    # returns true, if group could be added and user object
    # was saved successfully
    #
    # * <tt>group</tt> - The group object to be added to this user
    #
    def add_group!( group )
      save if add_group( group )
    end
    alias_method :<<, :add_group!

    # Removes a group from this user object
    # object is not being saved after this method call
    # returns true, if group could be removed
    #
    # * <tt>group</tt> - The group object to be removed from this user's group_ids
    #
    def remove_group( group )
      raise TypeError.new('not a group') unless group.is_a?(Ecore::Group)
      tmp_group_ids = self.group_ids.split(',')
      tmp_group_ids.delete(group.id)
      self.group_ids = tmp_group_ids.join(',')
      true
    end

    # removes a group from this user object
    # and stores it if successful
    # returns true, if group could be removed
    # and the object was successfully saved to the db
    #
    # * <tt>group</tt> - The group object to be removed from this user's group_ids
    #
    def remove_group!( group )
      save if remove_group( group )
    end
   
    # Shows the user's membership
    # returns an array of Ecore::Group this user
    # is member of
    def groups
      group_ids.split(',').map do |gid|
        Ecore::Group.find(@user_id, :id => gid).receive
      end
    end


    private

    def encrypt_password
      if @password
        self.hashed_password = self.class.encrypt_password(@password) 
        gen_confirmation_key # reset confirmation key, so it can't be used twice
      end
    end

    def gen_confirmation_key
      self.confirmation_key = Digest::SHA512.hexdigest(Time.now.to_f.to_s) if (@password.nil? || ( @password && @password.empty?))
    end

    def setup_default_role
      self.role = ((Ecore::env.get(:users) && Ecore::env.get(:users)[:default_role]) ? Ecore::env.get(:users)[:default_role] : 'default') unless role
    end

    def set_attributes(attrs)
      set_default_attributes
      if attrs.is_a?(Hash) && attrs.keys.size > 0
        attrs.each_pair do |name, val|
          next if name == :type
          send(:"#{name}=", val)
        end
      end
    end

    def set_default_attributes
      @attributes ||= {}
      return unless self.class.db_setup_attributes
      self.class.db_setup_attributes.each_pair do |db_attr,val| 
        default_value = ((val.is_a?(Array) && val.size > 1 && val[1].is_a?(Hash) && val[1].has_key?(:default)) ? val[1][:default] : nil)
        @attributes[db_attr.to_sym] = default_value
        send(:"#{db_attr}=", default_value) if default_value
      end
    end

    def password_required_on_create
      if new_record? && self.class == Ecore::User
        (@errors[:password] = ["password required"] ; return false) unless @password
      end
      true
    end

    def unique_name
      (@errors[:name] = ["must_be_unique"] ; return false) if (new_record? && @name && Ecore::db[:users].filter(:name => @name).count > 0)
      true
    end

  end
end
