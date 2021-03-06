module Ecore

  # A link is a physical node in the repository
  # if called, it will return the contents of the document
  # it links to. If modified, it will modify the original
  # document as well. A link can be seen like a symbolic link
  # in the unix filesystem
  class Link
    include Ecore::DocumentResource

    default_attributes

    attribute :orig_document_id, :string, :null => false
    attribute :orig_document_type, :string, :null => false

    validate :presence, :orig_document_id
    validate :presence, :orig_document_type

    after :initialize, :setup_orig_document_attributes
    before :update, :update_orig_document
    after :create, :setup_document_link_type

    # Overwrite default reload function and set original values again as well
    def reload
      set_attributes(Ecore::db[table_name].first(:id => @id))
      setup_orig_document_attributes
      self
    end

    def children(options={:type => nil, :get_dataset => false, :recursive => false, :reload => false, :preconditions => {:hidden => false}})
      orig_document.children(options)
    end

    def orig_document
      return @orig_document if @orig_document
      @orig_document = Ecore::Document.find(@group_ids || @user_id).filter(:id => self.orig_document_id).receive
    end

    private

    def setup_orig_document_attributes
      return if new_record?
      self.orig_document_type.constantize.db_setup_attributes.each_pair do |name, type_options|
        next if no_overrides.include? name
        self.class.create_attribute_methods(name, type_options[0], type_options[1], true)
      end
      attrs = Ecore::db[self.orig_document_type.underscore.pluralize.to_sym].first(:id => self.orig_document_id)
      if attrs.is_a?(Hash) && attrs.keys.size > 0
        attrs.each_pair do |name, val|
          next if no_overrides.include? name
          send(:"#{name}=", val)
        end
      end
      @changed_attributes = nil
    end

    def no_overrides
      [:type, :name, :id, :path, :tags, :starred, :label_ids, :position, :updated_at, :updated_by, :acl_read, :acl_write, :acl_delete, :hidden]
    end

    def update_orig_document
      if changed_attributes
        no_overrides.each {|noattr| changed_attributes.delete(noattr) }
        return if changed_attributes.size < 1
        Ecore::db[self.orig_document_type.underscore.pluralize.to_sym].filter(:id => self.orig_document_id).update(changed_attributes)
      end
    end

    def setup_document_link_type
      Ecore::db[:documents].filter(:id => @id).update(:link_type => @orig_document_type)
    end

  end

end
