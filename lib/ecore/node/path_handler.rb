module Ecore
  class NodePath

    def initialize(session, path,id)
      @path = path
      @id = id
      @session = session
    end

    def find(attrs, order="name, created_at DESC")
      Ecore::Node.find( @session, :conditions => {:path => "#{@path}#{@id}/"}.merge(attrs), :order => order )
    end

    def size
      Ecore::Node.find( @session, :path => "#{@path}#{@id}/" ).size
    end

    def <<(node)
      node.update_attributes(:path => "#{@path}#{@id}/")
    end

  end

  module PathHandler

    attr_accessor :parent_node_id

    # recursively iterates through node's children
    # and destroys each of them
    # calls children.destroy! (will throw error if anything goes wrong)
    # and then destroy!
    def recursive_destroy
      Ecore::Node.find( session, "path LIKE '#{path}#{id}/%'" ).each do |child|
        child.destroy!
      end
      destroy!
    end

    # returns a NodeArray of child nodes which are associated with
    # the node's path
    def children
      Ecore::NodePath.new(session,path,id)
    end

    # returns the node's parent or nil if node has no parent
    def parent
      return nil if path == "/"
      Ecore::Node.first( session, :id => "#{path[path[0..-2].rindex('/')+1..-2]}" )
    end

    # set a parent for this node
    # @paremeter node (acts_as_node enabled ecore node)
    def parent=(node)
      return nil unless node.class.respond_to?(:acts_as_node)
      @parent_node_id = node.id
    end

  end
end
