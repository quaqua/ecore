module Ecore
  module Hooks

    protected

    def update_modifier
      self.updated_by = session.user.id
      self.updated_at = Time.now
    end

    def audit_log_after_create
      return unless @session
      Ecore::AuditLog.create(:action => (@audit_action || "created"), :tmpnode => self, :tmpuser => @session.user, :summary => @audit_summary) 
    end

    def audit_log_after_update
      return unless @session
      Ecore::AuditLog.create(:action => (@audit_action || "modified"), :tmpnode => self, :tmpuser => @session.user, :summary => @audit_summary) 
    end

    def audit_log_after_destroy
      return unless @session
      Ecore::AuditLog.create(:action => (@audit_action || "deleted"), :tmpuser => @session.user, :tmpnode => self, :summary => (@audit_summary || name)) 
    end

    def write_acl
      if can_share?
        self.hashed_acl = acl.keys.inject(String.new){ |str, key| str << "#{key}:#{@acl[key].privileges}," ; str }
      end
    end

    def check_and_set_path_and_copy_acl
      if !@parent_node_id.blank? && (parent.nil? || (parent && parent.id != @parent_node_id)) && (@parent_node_id != id)
        if new_parent = Ecore::Node.first( @session, :id => @parent_node_id )
          self.path = "#{new_parent.path}#{new_parent.id}/"
          new_parent.acl.each_pair do |user_id, ace|
            @acl ||= Acl.new
            @acl << { :user_id => user_id, :privileges => ace.privileges }
          end
          simple_add_label( new_parent )
          if new_record? and respond_to?(:color) and new_parent.respond_to?(:color)
            self.color = new_parent.color
          end
        end
        @parent_node_id = nil
      end
      self.path = path.sub("#{id}","").sub("//","/") if path && path.include?("#{id}")
    end

    def set_default_path
      unless path
        self.path = '/'
      end
    end

    def check_write_permission
      raise SecurityTransgression unless can_write?
    end

    def check_delete_permission
      raise SecurityTransgression unless can_delete?
    end

    def setup_session_user_as_owner
      raise Ecore::MissingSession unless @session or @session.is_a?(Ecore::Session)
      direct_share( @session.user, 'rwsd' ) if @session
    end

    def setup_created_by
      self.created_by = @session.user.id
    end

    def unlink_labeled_nodes
      nodes.each { |n| n.remove_label( self ) }
    end

    private

    # the share method is creating audit log, this causes troubles on create
    # that's why this method is here for inheriting on create
    def direct_share( user, privileges )
      @acl ||= Acl.new
      @acl << { :user_id => user.id, :privileges => privileges }
    end

  end
end
