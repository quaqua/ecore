class Comment < ActiveRecord::Base

  attr_accessor :session

  def user
    Ecore::User.find_by_id(user_id)
  end

  def node
    return if @session.nil? or !Ecore::Node.registered.include?(node_type)
    node_type.constantize.first(@session, :id => node_id)
  end

end
