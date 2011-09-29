require File::expand_path('../ace',__FILE__)

module Ecore

  class PrivilegesTransgression < StandardError
  end

  class SecurityTransgression < StandardError
  end
    
  # Access Control list
  # for Ecore::Node
  class Acl < Hash
    
    # adds a given user or user's id address with
    # given privileges to this acl
    # e.g.:
    # acl << karl@localhost.loc, 'rw' # adds user karl@localhost.loc with read/write
    #                                 # permissions to this acl
    # acl << user, 'rwsd'        # adds user object 
    def <<(options)
      if options.has_key?(:user)
        user, privileges = options[:user], options[:privileges]
        raise PrivilegesTransgression.new("anybody can't get more than write permissions") if [User.anybody.id,User.everybody.id].include?(user.id) and privileges != 'r'
        self[user.id] = Ace.new(:user_id => user.id, :privileges => privileges)
      elsif options.has_key?(:user_id)
        user_id, privileges = options[:user_id], options[:privileges]
        raise PrivilegesTransgression.new("anybody can't get more than write permissions") if [User.anybody.id,User.everybody.id].include?(user_id) and privileges != 'r'
        self[user_id] = Ace.new(:user_id => user_id, :privileges => privileges)
      end
    end
    alias_method :push, :<<
    
    # returns true or false if given user or given user's id
    # address can read within this acl
    def can_read?(user)
      raise TypeError.new('no user was given, when asking for read permissions') if user.nil?
      return true if ((has_key?(User.anybody.id) and self[User.anybody.id].can_read?))
      return true if ((has_key?(User.everybody.id) and self[User.everybody.id].can_read?) and not user.nil? and not user.id == Ecore::User.anybody.id)
      return true if ((has_key?(user.id) and self[user.id].can_read?))
      user.groups.each do |group|
        return true if can_read?(group)
      end if user.is_a?(Ecore::User)
      false
    end
    
    # returns true or false if given user or given user's id
    # address can write within this acl
    def can_write?(user)
      return true if (has_key?(user.id) and self[user.id].can_write?)
      user.groups.each do |group|
        return true if can_write?(group)
      end if user.is_a?(Ecore::User)
      false
    end
    
    # returns true or false if given user or given user's id
    # address can share (manage acls) within this acl
    def can_share?(user)
      return true if (has_key?(user.id) and self[user.id].can_share?)
      user.groups.each do |group|
        return true if can_share?(group)
      end if user.is_a?(Ecore::User)
      false
    end
    
    # returns true or false if given user or given user's id
    # address can delete this acl holding node
    def can_delete?(user)
      return true if (has_key?(user.id) and self[user.id].can_delete?)
      user.groups.each do |group|
        return true if can_delete?(group)
      end if user.is_a?(Ecore::User)
      false
    end
    
  end
    
end
