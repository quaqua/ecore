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
    # options:
    #
    #  * <tt>:type</tt> - an exclusive class name, which should be filtered
    #  * <tt>:get_dataset</tt> - if the database call should not be done yet (gives you ability to extend query with sequel syntax)
    #  * <tt>:recursive</tt> - finds any child in full hierarchical depth
    #  * <tt>:reload</tt> - forces reloading the children from the database (can be combined with any other option)
    #  * <tt>:keep_cache</tt> - keeps the cache (in case of a special reload call, this can save time of another database call after the special one
    #  * <tt>:preconditions</tt> - a hash containing preconditions for the store_preconditions call in the Sequel::Dataset extender
    #    * <tt>:hidden</tt> - include hidden files in search (default: false)
    #
    def children(options={:type => nil, :get_dataset => false, :recursive => false, :keep_cache => true, :reload => false, :preconditions => {:hidden => false}})
      return @children_cache if @children_cache and !options[:get_dataset] and !options[:reload]
      klass = Ecore::db[:documents]
      if options[:type]
        raise(TypeError, ":type must be an Ecore::DocumentResource") unless options[:type].respond_to?(:table_name)
        klass = Ecore::db[:"#{options[:type].table_name}"]
      end
      query = klass.store_preconditions((@group_ids || @user_id),self.class.get_type_if_has_superclass,self,nil,(options[:preconditions] || {:hidden => false}))
      query = ( options[:recursive] ? query.where(:path.like("#{absolute_path}%")) : query.where(:path => absolute_path) )
      return query if options[:get_dataset]
      children_cache = query.order(:position,:name).receive(:all)
      return children_cache if options[:keep_cache]
      @children_cache = children_cache
    end

    # extracts last id from path (which should be parent_id)
    def parent_id
      @path.split('/').last
    end

    # Sets the parent_id (and calculates the full path of parent, so it can
    # be set without any further effort.
    def parent_id=(p_id)
      return if p_id.nil? || p_id.empty? || p_id == parent_id
      user_id = @user_id
      if @group_ids
        user_id = @group_ids
      else
        if u = Ecore::User.first(@user_id)
          user_id = u.id_and_group_ids
        end
      end
      @parent_cache = Ecore::Document.find(user_id, :hidden => true).filter(:id => p_id).receive
      @old_path = self.path
      self.path = @parent_cache.absolute_path
      @path_changed = self.path
      @acl_read = @parent_cache.acl_read
      @acl_read << ",#{@user_id}" unless @acl_read.include?(@user_id)
      @acl_write = @parent_cache.acl_write
      @acl_write << ",#{@user_id}" unless @acl_write.include?(@user_id)
      @acl_delete = @parent_cache.acl_delete
      @acl_delete << ",#{@user_id}" unless @acl_delete.include?(@user_id)
    end

    # returns the document's parent
    def parent(reload=false)
      return nil if parent_id.nil?
      return @parent_cache if @parent_cache && (reload.to_s != "reload")
      user_id = @user_id
      if @group_ids
        user_id = @group_ids
      else
        if u = Ecore::User.first(@user_id)
          user_id = u.id_and_group_ids
        end
      end
      @parent_cache = Ecore::Document.find(user_id, :hidden => true).where(:id => parent_id).receive
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
    def ancestors(reverse=nil,reload=nil,options={})
      return @ancestors_cache if @ancestors_cache && reload.nil?
      p = path.split('/')
      p.reverse! if reverse == :reverse
      @ancestors_cache = p.inject([]) do |arr,doc_id|
        if doc_id and !doc_id.empty?
          user_id = (@group_ids || @user_id)
          if options[:type]
            k = options[:type].find(user_id).where(:id => doc_id).receive
            arr << k if k
          else
            d = Ecore::Document.find(user_id).where(:id => doc_id).receive
            arr << d if d
          end
        end
        arr
      end
    end

  end
end
