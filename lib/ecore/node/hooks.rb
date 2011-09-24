module Ecore
  module Hooks

    protected

    def update_modifier
      self.updated_by = session.user.id
      self.updated_at = Time.now
    end

    def audit_log_after_create
      return unless @session
      Ecore::AuditLog.create(:action => "created", :tmpnode => self, :tmpuser => @session.user, :summary => @audit_summary) 
    end

    def audit_log_after_update
      return unless @session
      Ecore::AuditLog.create(:action => "modified", :tmpnode => self, :tmpuser => @session.user, :summary => @audit_summary) 
    end

    def audit_log_after_destroy
      return unless @session
      Ecore::AuditLog.create(:action => "deleted", :tmpuser => @session.user, :tmpnode => self, :summary => (@audit_summary || name)) 
    end

    def write_acl
      if can_share?
        self.hashed_acl = acl.keys.inject(String.new){ |str, key| str << "#{key}:#{@acl[key].privileges}," ; str }
      end
    end

    def check_and_set_path_and_copy_acl
      if @parent_node_id
        if parent = Ecore::Node.first( @session, :id => @parent_node_id )
          self.path = "#{parent.path}#{parent.id}/"
          parent.acl.each_pair do |user_id, ace|
            direct_share( ace.user, ace.privileges )
          end
        end
      end
      self.path = path.sub("/#{id}/","") if path && path.include?("#{id}")
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
      @acl << { :user => user, :privileges => privileges }
    end

  end
end
