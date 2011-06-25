module Ecore
  module AclExtensions

    def read_acl
      @acl = Acl.new
      hashed_acl.split(',').each do |ace_str|
        @acl[ace_str.split(':')[0]] = Ace.new(:user_id => ace_str.split(':')[0], 
                                              :privileges => ace_str.split(':')[1])
      end if hashed_acl
    end

    def acl(reload=false)
      return @acl if @acl and !reload
      read_acl
      @acl
    end

    def acl=(acls)
      @acl = acls
    end

    # returns privileges for current node's session
    def privileges(user=@session.user)
      eff_acl = effective_acl
      if eff_acl[user.id]
        return eff_acl[user.id].privileges
      end
      return eff_acl[Ecore::User.everybody.id].privileges if eff_acl[Ecore::User.everybody.id] and !user.id == Ecore::User.anybody.id
      return eff_acl[Ecore::User.anybody.id].privileges if eff_acl[Ecore::User.anybody.id]
    end

    # checks, if given user has read access for this
    # node or for parent node
    def can_read?(user=@session.user)
      effective_acl.can_read?(user)
    end

    # returns effective acl also considering label nodes
    def effective_acl(parsed_labels=[])
      acl
    end

    # alias for acl.can_write?(@session.user)
    def can_write?(user=@session.user)
      effective_acl.can_write?(user)
    end

    # alias for acl.can_share?(@session.user)
    def can_share?(user=@session.user)
      effective_acl.can_share?(user)
    end

    # alias for acl.can_delete?(@session.user)
    def can_delete?(user=@session.user)
      effective_acl.can_delete?(user)
    end

    # shares current node with user and provides access given as
    # privileges
    # e.g.:
    # node.share( user, 'rw' )
    def share( user, privileges )
      if (user.is_a?(Ecore::User) or user.is_a?(Ecore::Group)) and can_share?
        acl << { :user => user, :privileges => privileges }
        Ecore::AuditLog.create(:action => "shared", :tmpnode => self, :tmpuser => @session.user, :summary => "#{user.name} (#{user.class.name}) #{privileges}")
        nodes.each{ |n| n.share!( user, privileges ) if n.can_share? }
        return true
      end
      false
    end

    # shares a node and saves it
    #
    # ==== Parameters
    #
    # +user+ - the user object to share this node with
    # +privlieges+ - privileges string, like 'r', 'rw', 'rws', 'rwsd'
    #
    def share!( user, privileges )
      save if share( user, privileges )
    end

    # removes user from current node acls
    def unshare( user )
      if (user.is_a?(Ecore::User) or user.is_a?(Ecore::Group)) and can_share? and acl.has_key?( user.id )
        return false if user.id == session.user.id
        acl.delete(user.id)
        Ecore::AuditLog.create(:action => "unshared", :tmpnode => self, :tmpuser => @session.user, :summary => "#{user.name} (#{user.class.name})")
        nodes.each{ |n| n.unshare!( user ) if n.can_share? }
        return true
      end
      false
    end

    # unsahres a node and saves it immediately
    #
    # ==== Parameters
    #
    # +user+ - the user object to unshare this node with
    def unshare!( user )
      save if unshare( user )
    end

  end

end
