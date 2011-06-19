module Ecore
  module Hooks

    protected

    def update_modifier
      self.updated_by = session.user.id
      self.updated_at = Time.now
    end

    def audit_log_after_create
      return unless @session
      audits.create(:action => "created", :node_name => name, :user => @session.user, :summary => @audit_summary) 
    end

    def audit_log_after_update
      return unless @session
      audits.create(:action => "modified", :node_name => name, :user => @session.user, :summary => @audit_summary) 
    end

    def audit_log_after_destroy
      return unless @session
      audits.create(:action => "deleted", :user => @session.user, :node_name => name, :summary => @audit_summary) 
    end

    def write_acl
      if can_share?
        self.hashed_acl = acl.keys.inject(String.new){ |str, key| str << "#{key}:#{@acl[key].privileges}," ; str }
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
      @acl ||= Acl.new
      @acl << { :user => @session.user, :privileges => 'rwsd' } if @session
    end

    def setup_created_by
      self.created_by = @session.user.id
    end

    def unlink_labeled_nodes
      nodes.each { |n| n.remove_label( self ) }
    end

  end
end
