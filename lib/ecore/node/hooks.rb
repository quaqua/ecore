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

    def check_and_set_primary_label_and_copy_acl
      if @primary_label_id
        if plabel = Ecore::Node.first( @session, :id => @primary_label_id )
          if add_label( plabel, :primary )
            plabel.acl.each_pair do |user_id, ace|
              direct_share( ace.user, ace.privileges )
            end
          end
        end
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
