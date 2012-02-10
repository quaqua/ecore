module Ecore

  # Raised, if link can't be created
  class LinkError < StandardError
  end

  module LinkMixins

    # Links current document to another destination. This will only
    # work, if the given path is different from the document's current
    # path.
    #
    # * <tt>link_path</tt> - The path, the link should point to
    # * <tt>options</tt>
    #   * <tt>:name</tt> - String, defaults to original document name
    #
    # examples:
    #   document.link_to("")
    #   # => <Ecore::Link @name => document.name, ...>
    #   document.link_to(document.path, :name => "Link name")
    #   # => <Ecore::Link @path => document.path, @name => "Link name" ...>
    #
    def link_to(link_path, options={})
      options = {:name => @name}.merge(options).merge(:orig_document_id => @id, :orig_document_type => self.class.name, :path => link_path)
      if is_a?(Ecore::Link)
        options[:orig_document_id] = orig_document_id
        options[:orig_document_type] = orig_document_type
      end
      counter = 1
      while link_path == path && (options[:name] == @name || Ecore::Document.find(@group_ids || @user_id).filter(:path => @path, :name => options[:name]).count > 0)
        options[:name] = "#{@name} #{counter}"
        counter += 1
      end
      Ecore::Link.create(@user_id, options)
    end

    # Returns all links this document is linked with
    def links(options={})
      options = {:get_dataset => false, :type => Ecore::Link, :reload => false, :preconditions => {:hidden => false}}.merge(options)
      return @links_chache if @links_chache and !options[:get_dataset] and !options[:reload]
      query = Ecore::db[options[:type].table_name].store_preconditions((@group_ids || @user_id),self.class.get_type_if_has_superclass,self,nil,(options[:preconditions] || {:hidden => false}))
      query = query.where(:orig_document_id => id)
      return query if options[:get_dataset]
      @links_chache = query.order(:name,:created_at).receive(:all)
    end

    private

    def destroy_link
      Ecore::db[:"ecore/links"].filter(:orig_document_id => @id).delete
    end

  end
end
