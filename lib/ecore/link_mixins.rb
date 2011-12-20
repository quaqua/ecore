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
    #
    # examples:
    #   document.link_to("")
    #   # => <Ecore::Link @name => document.name, ...>
    #   document.link_to(document.path)
    #   # => nil
    #
    def link_to(link_path)
      raise(Ecore::LinkError, "cannot link to same path #{link_path}==#{path}") if link_path == path
      Ecore::Link.create(@user_id, :name => @name, :orig_document_id => @id, :orig_document_type => self.class.name, :path => link_path)
    end

    # Returns all links this document is linked with
    def links(options={:get_dataset => false, :reload => false, :preconditions => {:hidden => false}})
      return @links_chache if @links_chache and !options[:get_dataset] and !options[:reload]
      query = Ecore::db[:"ecore/links"].store_preconditions((@group_ids || @user_id),self.class.get_type_if_has_superclass,self,nil,(options[:preconditions] || {:hidden => false}))
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
