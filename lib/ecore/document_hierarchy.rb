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
      query = klass.store_preconditions((@user_obj || @group_ids || @user_id),nil,self,nil,(options[:preconditions] || {:hidden => false}))
      query = ( options[:recursive] ? query.where(:path.like("#{absolute_path}%")) : query.where(:path => absolute_path) )
      return query if options[:get_dataset]
      children_cache = query.order(:position,:name).receive(:all)
      return children_cache if options[:keep_cache]
      @children_cache = children_cache
    end

    # extracts last id from path (which should be parent_id)
    def parent_id
      @path.split('/').last if @path
    end

    # Sets the parent_id (and calculates the full path of parent, so it can
    # be set without any further effort.
    def parent_id=(p_id)
      return if p_id.nil? || p_id.empty? || p_id == parent_id
      user_id = @user_obj
      unless user_id
        user_id = @user_id
        if @group_ids
          user_id = @group_ids
        else
          if u = Ecore::User.first(@user_id)
            user_id = u
          end
        end
      end
      @parent_cache = Ecore::Document.find(user_id, :hidden => true).filter(:id => p_id).receive
      @old_path = self.path
      self.path = @parent_cache.absolute_path
      @path_changed = self.path
      @acl_read = @parent_cache.acl_read
      uid = (@user_obj ? @user_obj.id : user_id)
      @acl_read << ",#{uid}" unless @acl_read.include?(uid)
      @acl_write = @parent_cache.acl_write
      @acl_write << ",#{uid}" unless @acl_write.include?(uid)
      @acl_delete = @parent_cache.acl_delete
      @acl_delete << ",#{uid}" unless @acl_delete.include?(uid)
    end

    # returns the document's parent
    def parent(reload=false)
      return nil if parent_id.nil?
      return @parent_cache if @parent_cache && (reload.to_s != "reload")
      user_id = @user_obj
      unless user_id
        user_id = @user_id
        if @group_ids
          user_id = @group_ids
        else
          if u = Ecore::User.first(@user_id)
            user_id = u.id_and_group_ids
          end
        end
      end
      @parent_cache = Ecore::Document.find(user_id, :hidden => true).where(:id => parent_id).receive
    end

    # returns all ancestors of this document in an
    # Array
    #
    # parameters:
    #
    # * <tt>reverse</tt> - <b>[DEPRECATED]</b> Reverse the order of the ancestors. Default = false (starting with root ancestor)
    # * <tt>reload</tt> - <b>[DEPRECATED]</b> flush cache and reload ancestors from repository
    # * <tt>options</tt>
    #   * <tt>:type</tt> - Ecore::Document type to be looked up only default: nil (takes any doucment into account)
    #   * <tt>:include_self</tt> - include this document in returned array default: false
    #   * <tt>:reload</tt> - flush cache and perform a new query default: false
    #   * <tt>:reverse</tt> - return reversed order default: false
    #   * <tt>:get_dataset</tt> - returns the dataset without performing the query yet
    #
    # example:
    #   doc.ancestors
    #   # => [parent_of_parent,parent_doc]
    #
    #   doc.ancestors(nil,nil, :reverse => true)
    #   # => [parent_doc,parent_of_parent]
    #
    def ancestors(reverse=nil,reload=nil,options={})
      reload = options[:reload] if options[:reload]
      return @ancestors_cache if @ancestors_cache && reload.nil?
      user_id = (@user_obj || @group_ids || @user_id)
      p = path.split('/').inject([]){ |arr,id| arr << id if (id != "") ; arr }
      tmp = []
      if options[:type]
        tmp = options[:type].find(user_id).where(:id => p)
      else
        tmp = Ecore::Document.find(user_id).where(:id => p)
      end
      tmp = tmp.receive(:all) unless options[:get_dataset]
      @ancestors_cache = p.inject([]){ |arr,id| arr << nil }
      tmp.each { |d| @ancestors_cache[p.index(d.id)] = d }
      @ancestors_cache = @ancestors_cache.inject([]){ |arr,a| arr << a unless a.nil? ; arr }
      @ancestors_cache << self if options[:include_self]
      @ancestors_cache.reverse! if reverse == :reverse || options[:reverse]
      @ancestors_cache
=begin
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
      @ancestors_cache << self if options[:include_self]
      @ancestors_cache.reverse! if reverse == :reverse
      @ancestors_cache
=end
    end

  end
end
