require 'digest/sha2'
require File::expand_path('../../../../lib/ecore/node/uuid_generator',__FILE__)

module Ecore
  class User < ActiveRecord::Base
    
    include Ecore::UUIDGenerator
    
    class << self
        
      # returns the anybody User object. It is used with
      # Ecore::Session.new(:name => 'anybody') to get an anonymous session
      #
      def anybody
        anyb = new(:name => 'anybody')
        anyb.id = "000-00000-00000"
        anyb
      end
       
      # returns the everybody User object. This object is
      # used to grant privileges to a logged in user
      def everybody
        everyb = new(:name => 'everybody')
        everyb.id = "000-00000-00001"
        everyb
      end
      
      # encrypts the given password with the system's default password
      # encryption
      #
      # ==== Parameters
      #
      # +password+ - the clear text password to be encrypted
      #
      def encrypt_password(password)
        Digest::SHA512.hexdigest(password)
      end
      
    end
    
    attr_accessor :password, :session, :send_confirmation, :audit_summary, :skip_auditor
    
    has_many :audits, :class_name => "Ecore::AuditLog", :as => :auditable
    
    validates_uniqueness_of    :email, :if => :email?
    validates_uniqueness_of    :name, :if => :name?
    validates_format_of :name, :with => /^([a-z0-9A-Z\_\-\.]+)$/i, :if => :name?
    validates_format_of :email, :with => /^([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})$/i, :if => :email?
    
    before_create :gen_confirmation_key,
                  :setup_uuid
    after_create :audit_log_after_create
    after_update :audit_log_after_update
    before_save :encrypt_password
    
    # returns true if this user has role == 'manager'
    def is_admin?
      role == "manager"
    end

    # returns true if this user has role == 'editor'
    def is_editor?
      role == "editor"
    end
    
    # adds a group to this user
    # the group_id is allways stored within this
    # user object
    # the user object is not saved after this method call
    # returns true if the group could be added successfully
    #
    # ==== Parameters
    #
    # +group+ - the group object to be added to this user
    #
    def add_group( group )
      raise TypeError.new('not a group') unless group.is_a?(Ecore::Group)
      tmp_group_ids = self.group_ids.split(',')
      tmp_group_ids.delete(group.id)
      tmp_group_ids << group.id
      self.group_ids = tmp_group_ids.join(',')
      true
    end

    # adds a group to this user object
    # and stores the user object
    # returns true, if group could be added and user object
    # was saved successfully
    #
    # ==== Parameters
    #
    # +group+ - the group object to be added to this user
    #
    def add_group!( group )
      save if add_group( group )
    end
    alias_method :<<, :add_group!

    # removes a group from this user object
    # object is not being saved after this method call
    # returns true, if group could be removed
    #
    # ==== Parameters
    # 
    # +group+ - the group object which should be removed
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
    # ==== Parameters
    # 
    # +group+ - the group object which should be removed
    #
    def remove_group!( group )
      save if remove_group( group )
    end
   
    # shows the user's membership
    # returns an array of Ecore::Group this user
    # is member of
    def groups
      group_ids.split(',').inject(Array.new) do |arr,gid|
        arr << Ecore::Group.where(:id => gid).first
      end
    end
    
    # returns true, if this user is allowed to login to the system
    def enabled?
      !suspended
    end
    
    # returns true, if the user's last action has not been
    # performed before Ecore::env.get(:session_timeout)
    def online?
      last_request_at && last_request_at > 20.minutes.ago
    end
   
    private
    
    def encrypt_password
      if @password
        self.hashed_password = self.class.encrypt_password(@password) 
        gen_confirmation_key # reset confirmation key, so it can't be used twice
      end
    end
    
    def gen_confirmation_key
      self.confirmation_key = Digest::SHA512.hexdigest(Time.now.to_f.to_s) if @password.blank?
    end
            
    def audit_log_after_create
      audits.create(:action => "created", :node_name => name, :summary => @audit_summary) 
    end
    
    def audit_log_after_update
      return if @skip_auditor
      audits.create(:action => "updated", :node_name => name, :summary => @audit_summary)
    end
  
  end
end
