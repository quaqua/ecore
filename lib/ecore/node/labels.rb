module Ecore
  module Labels

    attr_accessor :primary_label_id

    # returns all nodes labeled with current node
    # this method is similar to a hierarchical "children" method
    #
    # ==== Paramters
    #
    # +options+ - options hash containing only :type => ClassName or "class_name"
    #
    def nodes(attrs={})
      if attrs.is_a?(Hash) and !attrs[:type].blank?
        const = attrs[:type]
        const = const.classify.constantize if const.is_a?(String)
        const.find(session, "label_node_ids LIKE '%#{id}%'")
      else
        Ecore::Node.find(session, "label_node_ids LIKE '%#{id}%'")
      end
    end

    # finds all nodes within the current node (similar to find method, but
    # not session is required). Only :conditions => "STRING" is allowed
    #
    # ==== Parameters
    #
    # +find_options+ - like in active_record plus 'type' which will be
    # filtered out before passed on to active_record an only nodes of that
    # type will be looked up then. node_type can only take one class
    # 
    # e.g.:
    # @node.find(:type => Contact, :name => "strauss")
    #
    def find(options={})
      ns = NodeArray.new
      type = options.delete(:type)
      nodes(:type => type).each do |n|
        if options.size > 0 and options.is_a?(Hash)
          met = true
          options.each_pair do |key,value|
            met = false if n.send("#{key}") != value
          end
          ns << n if met
        else
          ns << n
        end
        ns |= n.find(options.merge(:type => type))
      end
      ns
    end

    # returns all nodes in a Ecore::NodeArray this node is labeled with
    #
    def labels(options={})
      return NodeArray.new if new_record? 
      get_label_arr.inject(NodeArray.new) do |arr,label_field|
        next if options and options[:type] and ((options[:type].is_a?(String) && options[:type] != label_field.split(':')[1]) or (options[:type].is_a?(Array) && options[:type].include?(label_field.split(':')[1])))
        if n = label_field.split(':')[1].constantize.first(session, :id => label_field.split(':')[0])
          n.session = session
          arr << n
        end
        arr
      end
    end

    # adds a label to this node
    # does not call save
    #
    # ==== Parameters
    #
    # +node+ - the node, this node should get labeled with
    # +primary+ - default: :false, :primary will make given node the primary label, meaning, the first in the array
    #
    def add_label( n, primary=:false )
      raise InvalidNodeError.new('given node is not a node') unless n.class.respond_to?(:acts_as_node)
      return false if !can_write? and !new_record?
      return false if n.id == id
      return false if n.ancestors.map{ |a| a.id }.include?(id)
      label_arr = get_label_arr
      label_arr.delete(n_field(n))
      if primary == :primary
        label_arr = [n_field(n)]+label_arr
      else
        label_arr << n_field(n)
      end
      self.label_node_ids = label_arr.join(',')
      n.acl.each_pair{ |k,ace| share( ace.user, ace.privileges ) }
      true
    end

    # adds a label to this node and saves it
    #
    # ==== Parameters
    #
    # +node+ - the node to be added
    # +primary+ - symbol :primary, :false, defauld is :false
    #
    def add_label!( n, primary=:false )
      save if add_label( n, primary )
    end
    
    # adds given node as a child node of current node
    # labels given node with current node and saves it
    #
    # ==== Parameters
    #
    # +node+ - the node tho be labeled with this node
    #
    def <<( n )
      n.add_label!( self )
    end

    # removes a label from this node, but does not
    # save it to the database yet
    #
    # ==== Parameters
    #
    # +node+ - the node which should be removed
    #
    def remove_label( n )
      raise InvalidNodeError.new('given node is not a node') unless n.class.respond_to?(:acts_as_node)
      return false unless can_share?
      label_arr = get_label_arr
      label_arr.delete(n_field(n))
      self.label_node_ids = label_arr.join(',')
      remove_acls( n )
      true
    end

    # removes a label from this node and saves this node to the database
    #
    # ==== Parameters
    #
    # +node+ -  the node to be removed
    #
    def remove_label!( n )
      save if remove_label( n )
    end

    # returns the primary label of current node
    #
    def primary_label
      return nil if new_record?
      label_arr = get_label_arr
      label_arr.first.split(':')[1].constantize.first(session, :id => label_arr.first.split(':')[0]) if label_arr.size > 0
    end

    # sets given node as the primary label
    # equal to add_label( node, :primary )
    #
    # ==== Parameters
    #
    # +node+ - the node this node should get labeled with
    #
    def primary_label=( node )
      add_label( node )
    end

    # returns all predecessor primary_labels (as nodes) until on top
    def ancestors(labels=[])
      ancs = []
      if primary_label and !labels.include?(primary_label.id)
        ancs << primary_label
        ancs = primary_label.ancestors(labels << primary_label.id) + ancs
      end
      ancs
    end

    private

    def get_label_arr
      return [] unless label_node_ids
      label_node_ids.split(',')
    end

    def n_field( n )
      "#{n.id}:#{n.class.name}"
    end

    def remove_acls( n )
      n.acl.each_pair do |key, ace|
        unshare( ace.user )
      end
      labels.each do |label|
        label.acl.each_pair do |key, ace|
          share( ace.user, ace.privileges )
        end
      end
    end

  end
end
