module Ecore
  class AuditLog < ActiveRecord::Base
  
    attr_accessor :session, :tmpuser, :tmpnode

    before_create :setup_user, :setup_node

    def user
      Ecore::User.find_by_id(user_id)
    end

    def node
      return if @session.nil? or !Ecore::Node.registered.include?(node_type)
      node_type.constantize.first(@session, :id => node_id)
    end

    private

    def setup_user
      self.user_id = @tmpuser.id if @tmpuser
    end

    def setup_node
      return unless @tmpnode
      self.node_id = @tmpnode.id
      self.node_type = @tmpnode.class.name
      self.hashed_acl = @tmpnode.hashed_acl if @tmpnode.respond_to?(:hashed_acl)
    end
    
  end
end
