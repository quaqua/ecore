module Ecore

  module PathHandler

    attr_accessor :parent_node_id

    # recursively iterates through node's children
    # and destroys each of them
    # calls children.destroy! (will throw error if anything goes wrong)
    # and then destroy!
    def recursive_destroy
      Ecore::Node.find( session, "path LIKE '#{path}#{id}/%'" ).each do |child|
        child.destroy
      end
      destroy
    end

    # returns a NodeArray of child nodes which are associated with
    # the node's path
    # @param attrs [Hash] a hash containing search attributes and switches like
    # :recursive => true (to do a full recursive search for children in any depth)
    # :type => "NodeClassName" to limit search for only nodes of given type
    def children(attrs={})
      cond = "path = '#{path}#{id}/'"
      cond = "path LIKE '#{path}#{id}/%'" if attrs.delete(:recursive)
      cond << " AND #{attrs[:conditions]}" if attrs[:conditions] 
      if attrs.is_a?(Hash) and !attrs[:type].blank?
        const = attrs.delete(:type)
        const = const.classify.constantize if const.is_a?(String)
        const.find(@session, cond )
      else
        Ecore::Node.find(@session, cond )
      end
    end
    
    # moves a node (including all it's subnodes to a new destination
    def move_to(new_path)
      nodes = Ecore::Node.find( @session, "path LIKE '%#{path}#{id}/%'" )
      nodes.each do |n|
        n.path = n.path.sub(path,new_path)
        n.save
      end
      self.path = new_path
      save
    end
    
    # adds a new child node to the curren tnode
    def add_child(node)
      acl.each_pair{ |k,ace| node.share( k, ace.privileges ) }
      node.add_label(self)
      node.update_attributes(:path => "#{path}#{id}/")
    end
    
    # returns the node's parent or nil if node has no parent
    def parent
      return nil if path.blank? or path == "/"
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
