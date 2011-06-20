module Ecore
  
  # Access Control Entry
  # holds information about the user
  # and privileges
  class Ace
    
    # the access entry holder
    attr_accessor :user_id
    
    # the privileges as string
    attr_accessor :privileges
    
    # creates a new access control entry
    # e.g.:
    # Ecore::Ace.new(:user_id => user.id, 'rws')
    # would create a new entry for user with email (== unique id for users)
    # and privileges 'rws'
    # r...read
    # w...write
    # s...share
    # d...delete
    def initialize(options)
      self.user_id = options[:user_id]
      self.privileges = options[:privileges]
      raise TypeError.new("user must be given. got #{options.inspect}") unless self.user_id
    end

    # returns the ace's user
    def user
      return Ecore::User.anybody if @user_id == Ecore::User.anybody.id
      return Ecore::User.everybody if @user_id == Ecore::User.everybody.id
      u = Ecore::User.find_by_id(@user_id)
      u = Ecore::Group.find_by_id(@user_id) unless u
      u
    end
    
    # tells if this ace has read permissions
    def can_read?
      can?('r')
    end
    
    # tells if this ace has write permissions
    def can_write?
      can?('w')
    end
    
    # tells this ace has permissions to share
    def can_share?
      can?('s')
    end
    
    # tells if this ace has permissions to delete
    def can_delete?
      can?('d')
    end
    
    # sets privileges to read_only or nil. If set to nil,
    # Ace's user will be denied to view content from here on
    # in deeper hierarchy levels
    def can_read=(value)
      if value
        set_privileges('r', value)
      else
        self.privileges = nil
      end
    end
    
    # sets the 'w' in privileges or deletes it. 
    # leaves everything else as is
    def can_write=(value)
      set_privileges('d', value) unless value
      set_privileges('w', value)
    end
    
    # sets the 's' in privileges or deletes it.
    # leaves everything else as is
    def can_share=(value)
      set_privileges('s', value)
    end
    
    # sets the 'd' in privileges or deletes it.
    # leaves everything else as is
    def can_delete=(value)
      set_privileges('d', value)
      set_privileges('w', value)
    end
    
    # returns if given privileges are set in this Ace
    def can?(privileges)
      self.privileges and self.privileges.include?(privileges)
    end
    
    private
    
    def set_privileges(key, value)
      self.privileges = self.privileges.delete(key)
      self.privileges.concat(key) if value
      ensure_read_permissions
    end
    
    def ensure_read_permissions
      self.privileges.concat('r') if self.privileges.match('(w|s|d)') and not self.privileges.include?('r')
      self.privileges.concat('w') if self.privileges.include?('d') and not self.privileges.include?('w')
    end
    
  end
  
end
