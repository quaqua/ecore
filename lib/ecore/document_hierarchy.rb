module Ecore
  module DocumentHierarchy

    # returns the full path of this document in the repository
    # including it's id
    def absolute_path
      "#{@path}/#{@id}"
    end

    # prepares statement to receive
    # children of current document
    #
    # if :type option is given, only documents of this type will be fetched
    #
    # example:
    #   mydocument.children(:type => Folder)
    #   # => [<Child1>,<Child2>]
    #
    # example:
    #   mydocument.children(:exec => false).where(:name => 'test').receive(:all)
    #
    def children(options={:type => nil, :get_dataset => false, :reload => false})
      return @children_cache if @children_cache and !options[:get_dataset] and !options[:reload]
      klass = Ecore::db[:documents]
      if options[:type]
        raise(TypeError, ":type must be an Ecore::DocumentResource") unless options[:type].respond_to?(:table_name)
        klass = Ecore::db[:"#{options[:type].table_name}"]
      end
      query = klass.store_preconditions(@user_id,self.class.get_type_if_has_superclass,self).where(:path => absolute_path)
      return query if options[:get_dataset]
      @children_cache = query.receive(:all)
    end

    # extracts last id from path (which should be parent_id)
    def parent_id
      @path.split('/').last
    end

    # Sets the parent_id (and calculates the full path of parent, so it can
    # be set without any further effort.
    def parent_id=(p_id)
      return if p_id.empty?
      p = Ecore::Document.find(@user_id).filter(:id => p_id).receive
      self.path = p.absolute_path
      @acl_read = p.acl_read
      @acl_read << ",#{@user_id}" unless @acl_read.include?(@user_id)
      @acl_write = p.acl_write
      @acl_write << ",#{@user_id}" unless @acl_write.include?(@user_id)
      @acl_delete = p.acl_delete
      @acl_delete << ",#{@user_id}" unless @acl_delete.include?(@user_id)
    end

    # returns the document's parent
    def parent
      return nil if parent_id.nil?
      self.class.find(@user_id).where(:id => parent_id).receive
    end

    # returns all ancestors of this document
    #
    # example:
    #   doc.ancestors
    #   # => [parent_of_parent,parent_doc]
    #
    #   doc.ancestors(:reverse)
    #   # => [parent_doc,parent_of_parent]
    #
    def ancestors(reverse=nil,reload=nil)
      return @ancestors_cache if @ancestors_cache && reload.nil?
      p = path.split('/')
      p.reverse! if reverse == :reverse
      @ancestors_cache = p.inject([]) do |arr,doc_id|
        if doc_id and !doc_id.empty?
          arr << Ecore::Document.find(@user_id).where(:id => doc_id).receive
        end
        arr
      end
    end

  end
end
