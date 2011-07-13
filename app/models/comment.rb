class Comment < ActiveRecord::Base

  attr_accessor :session

  before_save :setup_acl

  def user
    Ecore::User.find_by_id(user_id)
  end

  def node
    return if @session.nil? or !Ecore::Node.registered.include?(node_type)
    node_type.constantize.first(@session, :id => node_id)
  end

  private

  def setup_acl
    self.hashed_acl = node.hashed_acl if node
  end

end
