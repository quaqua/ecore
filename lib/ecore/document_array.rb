module Ecore
  class DocumentArray < Array

    # creates a new array of children (documents of any kind)
    #
    # this method is actually only used by the document.children method
    def initialize(parent, arr)
      if parent
        @absolute_path = parent.absolute_path
        @acl_read = parent.acl_read
        @acl_write = parent.acl_write
        @acl_delete = parent.acl_delete
        @can_write = parent.can_write?
        @user_id = parent.user_id
      end
      super(arr)
    end

    # adds a new child to this array
    # and saves it to the repository
    #
    # @arguments
    #   :type - a DocumentResource class
    #   :attributes = attributes that should be taken to instanciate a class of type :type
    #
    # example:
    #   mydocument.children.create(MyDocument, :name => 'test', :bla => 'bla')
    #   # => <newchild_of_mydocument>
    #
    def create(type, child_attributes)
      raise(Ecore::SecurityTransgression, "not enough privileges for #{user_id} to create child in #{@absolute_path}") unless @can_write
      raise(TypeError, "type must be an Ecore::DocumentResource") unless type.respond_to?(:table_name)
      child = type.new(@user_id, child_attributes)
      child if push(child)
    end

    # adds an existing document to this array-holding document
    #
    # example:
    #   mydocument.children.push(childdocument)
    #   # => true
    #
    def push(child)
      child = setup_new_child_default_values(child)
      if child.save
        return super(child)
      end
      nil
    end
    alias_method :<<, :push

    private

    def setup_new_child_default_values(child)
      child.path = @absolute_path
      child.acl_read = @acl_read
      child.acl_write = @acl_write
      child.acl_delete = @acl_delete
      child.acl_delete << ",#{child.created_by}" if !child.new_record? && !child.acl_delete.include?(child.created_by)
      child
    end

  end
end
