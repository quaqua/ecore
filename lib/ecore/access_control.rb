module Ecore
  module AccessControl

    attr_accessor :acl_changed

    # shares a document with a given user or id
    #
    # write permissions are required to share a document
    # 
    # the document is not saved to the repository after this
    # method has been called!
    #
    # the second argument (privileges) defaults to read/write permission
    #
    # example:
    #   doc.share(user,'r')
    #   # => true
    #
    #   doc.share(user,'rwd')
    #   # => true #full access granted
    #
    #   doc.share(user_id, 'rw')
    #   # => true
    #
    #   doc.share(Ecore::User.anybody)
    #   # => true # anybody cannot get more than read access
    #
    #   doc.share(Ecore::User.anybody)
    #   # => true # still only got 'r' access
    #
    def share(user_id_or_user, privileges='rw')
      return false unless can_write?
      user_id = self.class.extract_id_from_user_id_or_user(user_id_or_user)
      privileges = 'r' if user_id == Ecore::User.anybody_id
      set_privileges_for(user_id, :acl_read, true)
      set_privileges_for(user_id, :acl_write, privileges.include?('w'))
      set_privileges_for(user_id, :acl_delete, privileges.include?('d'))
      @acl_changed ||= []
      @acl_changed << {:user_or_id => user_id_or_user, :privileges => privileges}
      Ecore::Audit.log(@id, self.class.name, @path, @name, "shared", @user_id, "account: #{user_id}, privileges: #{privileges}")
      true
    end

    def share!(user_id_or_user, privileges='rw')
      return save if share(user_id_or_user, privileges)
      false
    end

    # unshares a document
    #
    # write permissions are required to unshare a document
    #
    # example:
    #   doc.unshare(user)
    #   # => true
    #
    #   doc.unshare(user_id)
    #   # => true
    def unshare(user_id_or_user)
      return false unless can_write?
      user_id = self.class.extract_id_from_user_id_or_user(user_id_or_user)
      set_privileges_for(user_id, :acl_read, false)
      set_privileges_for(user_id, :acl_write, false)
      set_privileges_for(user_id, :acl_delete, false)
      @acl_changed ||= []
      @acl_changed << {:user_or_id => user_id_or_user, :removed => true}
      Ecore::Audit.log(@id, self.class.name, @path, @name, "unshared", @user_id, "account: #{user_id}")
      true
    end

    def unshare!(user_id_or_user)
      return save if unshare(user_id_or_user)
      false
    end

    def can_read?(user_id_or_user=nil)
      if user_id_or_user
        user_id = self.class.extract_id_from_user_id_or_user(user_id_or_user)
      else
        user_id = @group_ids || @user_id
      end
      return false unless @acl_read
      return true if @acl_read.include?(Ecore::User.anybody_id)
      return true if @acl_read.include?(user_id)
      if user = Ecore::User.first(user_id)
        user.groups.each do |group|
          return true if @acl_read.include?(group.id)
        end
      end
      false
    end

    def can_write?(user_id_or_user=nil)
      return true if new_record? # Problematic?
      return false unless @acl_write
      return true if @user_is_admin
      if user_id_or_user
        user_id = self.class.extract_id_from_user_id_or_user(user_id_or_user)
      else
        user_id = @group_ids || @user_id
        if user_id.include?(',')
          user_id.split(',').each do |u_id|
            return true if @acl_write.include?(u_id)
          end
        end
      end
      return true if @acl_write.include?(user_id)
      if user = Ecore::User.first(user_id)
        user.groups.each do |group|
          return true if @acl_write.include?(group.id)
        end
      end
      false
    end

    def can_delete?(user_id_or_user=nil)
      return false unless @acl_delete
      return true if @user_is_admin
      if user_id_or_user
        user_id = self.class.extract_id_from_user_id_or_user(user_id_or_user)
      else
        user_id = @group_ids || @user_id
        if user_id.include?(',')
          user_id.split(',').each do |u_id|
            return true if @acl_delete.include?(u_id)
          end
        end
      end
      return true if @acl_delete.include?(user_id)
      if user = Ecore::User.first(user_id)
        user.groups.each do |group|
          return true if @acl_delete.include?(group.id)
        end
      end
      false
    end

    private

    def set_privileges_for(user_id, rwd, grant=false)
      tmp = instance_variable_get("@#{rwd}") || ""
      tmp = tmp.split(',')
      tmp.delete(user_id)
      tmp << user_id if grant
      instance_variable_set("@#{rwd}",tmp.join(','))
    end

  end
end
