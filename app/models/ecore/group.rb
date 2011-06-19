require File::expand_path('../../../../lib/ecore/node/uuid_generator',__FILE__)

module Ecore
  class Group < ActiveRecord::Base
  
    include Ecore::UUIDGenerator
    
    has_many :acls
    
    validates_presence_of :name
    validates_uniqueness_of :name
    
    before_create :setup_uuid
    before_destroy :delete_group_ids
    
    # adds a user to this group
    # user object needs to be saved
    def add_user( user )
      raise TypeError.new('not a user') unless user.is_a?(Ecore::User)
      user.add_group(self)
    end

    # adds a user to this group
    # user object is called with save
    def add_user!( user )
      raise TypeError.new('not a user') unless user.is_a?(Ecore::User)
      user.add_group!(self)
    end
    alias_method :<<, :add_user!

    # removes a user from this group
    # 
    # ==== Parmaters
    #
    # +user+ - the user object to be removed
    #
    def remove_user( user )
      raise TypeError.new('not a user') unless user.is_a?(Ecore::User)
      user.remove_group(self)
    end

    # removes a user from this group
    # and saves the user object (which stores this information)
    #
    # ==== Parameters
    #
    # +user+ - the user object to be removed
    #
    def remove_user!( user )
      user.remove_group!( self )
    end
    
    # returns an Array of users associated with this group
    def users
      Ecore::User.where("group_ids LIKE '%#{id}%'").all
    end
    
    private
    
    def delete_group_ids
      users.each { |user| user.remove_group(self) }
    end
    
  end
end
