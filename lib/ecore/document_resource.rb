require 'active_model' if defined?(Rails)

require File::expand_path("../attribute_methods", __FILE__)
require File::expand_path("../hooks", __FILE__)
require File::expand_path("../validations", __FILE__)
require File::expand_path("../active_model_layer", __FILE__)
require File::expand_path("../dataset", __FILE__)
require File::expand_path("../access_control", __FILE__)
require File::expand_path("../document_hierarchy", __FILE__)
require File::expand_path("../document_array",__FILE__)
require File::expand_path("../link_mixins", __FILE__)
require File::expand_path("../unique_id_generator", __FILE__)
require File::expand_path("../label_mixins", __FILE__)

module Ecore

  class SavingFailed < StandardError
  end

  # raised, if anything goes wrong with a document operation.
  # e.g., if user has not enough privileges to write a document
  class SecurityTransgression < StandardError
  end

  module DocumentResource

    module ClassMethods

      def table_name
        return superclass.table_name if get_type_if_has_superclass
        name.underscore.pluralize.to_sym
      end

      def hidden
        @hidden = true
      end

      def hidden?
        @hidden
      end

      def default_attributes
        attribute :name, :string, :null => false
        attribute :color, :string
        attribute :starred, :boolean, :default => false
        attribute :position, :integer, :default => 0
        attribute :path, :string, :default => ""

        attribute :created_at, :datetime, :default => Time.now
        attribute :created_by, :string

        attribute :updated_at, :datetime
        attribute :updated_by, :string

        attribute :hidden, :boolean, :default => false

        validate :presence, :name
        after :destroy, :destroy_link
      end

      def migrate(options={:versions => false, :trash => false})
        default_attributes
        attrs = @db_setup_attributes || {}
        if Ecore::db.table_exists?(table_name)
          attrs.each_pair do |name, arr|
            unless Ecore::db[table_name].columns.include?(name)
              Ecore::db.add_column(table_name, name, arr[0], arr[1])
              Ecore::logger.info("column '#{name}' has been added to #{table_name}")
            end
          end
        else
          Ecore::db.create_table(table_name) do
            String  :id, :size => 8, :primary_key => true
            String  :type
            String  :acl_read, :null => false
            String  :acl_write, :null => false
            String  :acl_delete, :null => false
            String  :label_ids, :default => ""

            index   :type
            index   :name
            index   :path
            index   :acl_read
            index   :label_ids

            attrs.each_pair do |name, arr|
              String name, arr[1] if arr[0] == :string || arr[0] == String
              Fixnum name, arr[1] if arr[0] == :integer || arr[0] == Fixnum
              DateTime name, arr[1] if arr[0] == :datetime || arr[0] == DateTime
              Date name, arr[1] if arr[0] == :date || arr[0] == Date
              Time name, arr[1] if arr[0] == :time || arr[0] == Time
              Float name, arr[1] if arr[0] == :float || arr[0] == Float
              TrueClass name, arr[1] if arr[0] == :boolean || arr[0] == TrueClass || arr[0] == FalseClass
              TrueClass name, arr[1] if arr[0] == :bool
            end
          end
        end
        if options[:version] && !Ecore::db.table_exists?(:"#{table_name}_versions")
          Ecore::db.create_table(:"#{table_name}_versions") do
            String  :id, :size => 8, :primary_key => true
            String  :type
            String  :acl_read, :null => false
            String  :acl_write, :null => false
            String  :acl_delete, :null => false
            String  :label_ids, :default => ""

            index   :id
            index   :updated_at
            index   :path

            attrs.each_pair do |name, arr|
              String name, arr[1] if arr[0] == :string || arr[0] == String
              Fixnum name, arr[1] if arr[0] == :integer || arr[0] == Fixnum
              DateTime name, arr[1] if arr[0] == :datetime || arr[0] == DateTime
              Date name, arr[1] if arr[0] == :date || arr[0] == Date
              Time name, arr[1] if arr[0] == :time || arr[0] == Time
              Float name, arr[1] if arr[0] == :float || arr[0] == Float
              TrueClass name, arr[1] if arr[0] == :boolean || arr[0] == TrueClass || arr[0] == FalseClass
              TrueClass name, arr[1] if arr[0] == :bool
            end
          end
        end
        if options[:trash] && !Ecore::db.table_exists?(:"#{table_name}_trash")
          Ecore::db.create_table(:"#{table_name}_trash") do
            String  :id, :size => 8, :primary_key => true
            String  :type
            String  :acl_read, :null => false
            String  :acl_write, :null => false
            String  :acl_delete, :null => false
            String  :label_ids, :default => ""

            DateTime :deleted_at, :null => false
            String  :deleted_by, :null => false

            index   :updated_at
            index   :path
            index   :deleted_at
            index   :deleted_by

            attrs.each_pair do |name, arr|
              String name, arr[1] if arr[0] == :string || arr[0] == String
              Fixnum name, arr[1] if arr[0] == :integer || arr[0] == Fixnum
              DateTime name, arr[1] if arr[0] == :datetime || arr[0] == DateTime
              Date name, arr[1] if arr[0] == :date || arr[0] == Date
              Time name, arr[1] if arr[0] == :time || arr[0] == Time
              Float name, arr[1] if arr[0] == :float || arr[0] == Float
              TrueClass name, arr[1] if arr[0] == :boolean || arr[0] == TrueClass || arr[0] == FalseClass
              TrueClass name, arr[1] if arr[0] == :bool
            end
          end
        end
      end
   
      # creates a document and returns it
      def create(user_id_or_user, attrs={})
        doc = new(user_id_or_user,attrs)
        doc.save
        doc
      end

      # same as create, but raises an error, if save method
      # fails
      def create!(user_id_or_user, attrs={})
        doc = new(user_id_or_user,attrs)
        raise(SavingFailed, doc.errors) unless doc.save
        doc
      end

      # finds a document in the repository
      #
      # options:
      #
      # * <tt>:trashed</tt> - lookup in document's trash table (if configured)
      # * <tt>:hidden</tt> - also include hidden douments in lookup
      #
      # examples:
      #   MyDefinitionClass.find(user).where(:name.like('%hann%').where(:created_at.lt(Time.now)).receive(:all)
      #   # => [<mydefclassinst1>,<mydefclassinst2>]
      #
      #   MyDefinitionClass.find(user_id).where(:id => '2owietu2').receive
      #   # => mydefclassinst
      #
      def find(user_id_or_user, options={:trashed => false, :hidden => false})
        Ecore::db[:"#{table_name}#{"_trash" if options.delete(:trashed)}"].store_preconditions(user_id_or_user,get_type_if_has_superclass,nil,nil,options)
      end

      # extracts user id from user, if user object is given, if id is
      # given, it will get passed through
      def extract_id_from_user_id_or_user(user_id_or_user)
        user_id_or_user.is_a?(String) ? user_id_or_user : user_id_or_user.id
      end

      # returns type of this class in case it has been 
      # derived from another Ecore::DocumentResource enabled class
      def get_type_if_has_superclass
        (defined?(superclass) && superclass.respond_to?(:table_name)) ? name : nil
      end

    end

    include Ecore::ActiveModelLayer
    include Ecore::Validations::InstanceMethods
    include Ecore::Hooks::InstanceMethods
    include Ecore::AccessControl
    include Ecore::DocumentHierarchy
    include Ecore::LinkMixins
    include Ecore::LabelMixins

    def self.included(model)
      model.extend Ecore::AttributeMethods
      model.extend ClassMethods
      model.extend Ecore::Hooks::ClassMethods
      model.extend Ecore::Validations::ClassMethods
      model.extend Ecore::UniqueIDGenerator
      model.extend ActiveModel::Naming if defined?(Rails)
      @classes ||= []
      @classes.delete(model.name)
      @classes << model.name
    end

    def self.classes
      @classes
    end

    attr_reader :attributes, :changed_attributes, :user_id
    attr_accessor :id, :acl_read, :acl_write, :acl_delete, :label_ids, :deleted_by, :deleted_at

    def table_name
      self.class.table_name
    end

    # creates a new instance of this document resource
    #
    # a resource has to have a user, which deals with it. It
    # is not allowed to create documents without passing a user.
    # 
    # possible minimum use cases are:
    #   MyDoc.new(user, :name => 'document')
    # creates a new instance with user object as owner.
    #   MyDoc.new(session[:user_id], :name => 'document')
    # creates a new instance with given id
    def initialize(user_id_or_user, attrs={})
      if user_id_or_user.is_a?(String) && user_id_or_user.include?(',')
        @user_id = user_id_or_user.split(',').first
        @group_ids = user_id_or_user
      else
        @user_id = self.class.extract_id_from_user_id_or_user(user_id_or_user)
      end
      set_attributes(attrs)
      @changed_attributes = nil
      run_hooks(:after, :initialize)
    end

    # saves the document to the repository and returns true, if validations, hooks ans
    # actual saving have been successfully processed
    def save
      raise StandardError, "table does not exist yet in the database (run #{self.class.table_name.to_s.classify}.migrate)" unless Ecore::db.table_exists?(table_name)
      return false unless run_validations
      this_new_record = new_record?
      success = false
      begin
        if this_new_record
          default_private_setup_hooks_init
          run_hooks(:before,:create) if this_new_record
          run_hooks(:before,:save)
          Ecore::db.transaction do
            @id = self.class.gen_unique_id
            Ecore::db[table_name].insert(attributes.merge(:created_at => @created_at,
                                                          :created_by => @created_by,
                                                          :type => @type,
                                                          :id => @id,
                                                          :acl_read => @acl_read, 
                                                          :acl_write => @acl_write, 
                                                          :acl_delete => @acl_delete, 
                                                          :label_ids => @label_ids,
                                                          :updated_at => @updated_at,
                                                          :updated_by => @updated_by))
            Ecore::db[:documents].insert(:id => @id, :type => self.class.name, :name => @name, :updated_at => Time.now, :updated_by => @user_id, :acl_read => @acl_read, :path => @path, :label_ids => @label_ids, :hidden => @hidden, :position => @position)
            Ecore::Audit.log(@id, self.class.name, @name, "created", @user_id)
            @changed_attributes = nil
            success = true
          end 
        else # if not new record
          run_hooks(:before,:update)
          run_hooks(:before,:save)
          Ecore::db.transaction do
            save_attrs = attributes
            save_attrs.delete(:created_by)
            save_attrs.delete(:created_at)
            save_attrs.delete(:type)
            save_attrs.delete(:id)
            Ecore::db[table_name].where(:id => @id).update(save_attrs.merge(:acl_read => @acl_read, 
                                                                            :acl_write => @acl_write, 
                                                                            :acl_delete => @acl_delete, 
                                                                            :label_ids => @label_ids,
                                                                            :updated_at => Time.now,
                                                                            :updated_by => @user_id))
            Ecore::db[:documents].where(:id => @id).update(:name => @name, :updated_at => Time.now, :updated_by => @user_id, :acl_read => @acl_read, :path => @path, :label_ids => @label_ids, :hidden => @hidden, :position => @position)
            if @acl_changed && @acl_changed.is_a?(Array)
              Ecore::Document.find(@group_ids || @user_id).where(:path.like("#{absolute_path}%")).receive(:all).each do |child|
                @acl_changed.each do |acl|
                  next unless child.can_write?
                  if acl[:removed]
                    child.unshare(acl[:user_or_id])
                  else
                    child.share(acl[:user_or_id],acl[:privileges])
                  end
                  child.save
                end
              end
            end
            if @path_changed && @path_changed.is_a?(String)
              Ecore::Document.find((@group_ids || @user_id), :hidden => true).where(:path.like("#{@old_path}/#{@id}%")).receive(:all).each do |child|
                child.path = child.path.sub(@old_path,@path)
                child.acl_read = acl_read
                child.acl_write = acl_write
                child.acl_delete = acl_delete
                child.save
              end
            end
            Ecore::Audit.log(@id, self.class.name, @name, "updated", @user_id, @changed_attributes.inspect)
            @changed_attributes = nil
            success = true
          end 
        end
      rescue StandardError => e
        Ecore::logger.error e.inspect
        @id = nil if this_new_record
        @errors ||= {}
        @errors[:DB] = ['could not save document to repository']
      end
      return false unless success
      run_hooks(:after,:create) if this_new_record
      run_hooks(:after,:update) unless this_new_record
      run_hooks(:after,:save)
      true
    end

    # updates a document by taking a hash with attributes that should get udpated
    def update(attrs)
      attrs.each_pair do |key, value|
        send("#{key}=",value)
      end
      save
    end

    # destroys (moves) a document to the trash
    # but if :permanent => true is used, it will permanently be remoed from the reopsitory
    #
    # this will also remove document's children in the same manner
    #
    # examples:
    #   doc.destroy
    #   # => true
    #   doc.destroy(:permanent => true)
    #   # => true
    #
    def destroy(options={:permanent => false})
      return false if new_record? || @id.nil?
      return false unless can_delete?
      success = false
      begin
        run_hooks(:before,:destroy)
        Ecore::db.transaction do
          if trashed?
            Ecore::db[:"#{table_name}_trash"].where(:id => @id).delete
            Ecore::db[:documents_trash].where(:id => @id).delete
          else
            if !options[:permanent] && Ecore::db.table_exists?(:"#{table_name}_trash")
              Ecore::db[:"#{table_name}_trash"].insert(Ecore::db[table_name].first(:id => @id).merge(:deleted_at => Time.now, :deleted_by => @user_id))
              Ecore::db[:documents_trash].insert(Ecore::db[:documents].first(:id => @id).merge(:deleted_at => Time.now, :deleted_by => @user_id))
            end
            Ecore::db[table_name].where(:id => @id).delete
            Ecore::db[:documents].where(:id => @id).delete
          end
          children.each do |child|
            raise(SavingFaild, "could not destroy #{child.name}") unless child.destroy(options)
          end
          success = true
        end 
      end
      return false unless success
      run_hooks(:after,:destroy)
      success
    end

    # returns true if document is in trash
    def trashed?
      @deleted_at.is_a?(Time)
    end

    # restores a document
    def restore
      success = false
      begin
        Ecore::db.transaction do
          if trashed?
            attrs = Ecore::db[:"#{table_name}_trash"].first(:id => @id)
            attrs.delete(:deleted_at)
            attrs.delete(:deleted_by)
            Ecore::db[table_name].insert(attrs)
            attrs = Ecore::db[:documents_trash].first(:id => @id)
            attrs.delete(:deleted_at)
            attrs.delete(:deleted_by)
            Ecore::db[:documents].insert(attrs)
            Ecore::db[:"#{table_name}_trash"].where(:id => @id).delete
            Ecore::db[:documents_trash].where(:id => @id).delete
          end
          success = true
        end 
      #rescue StandardError => e
      #  Ecore::logger.error e.inspect
      #  @errors ||= {}
      #  @errors[:DB] = ['could not remove document from repository']
      end
      success
    end

    # reloads attributes from database
    def reload
      set_attributes(Ecore::db[table_name].first(:id => @id))
      self
    end

    # returns the updated_by as a Ecore::User instance
    def updater
      Ecore::User.first(@updated_by)
    end

    private

    def default_private_setup_hooks_init
      @acl_read ||= @user_id.to_s
      @acl_write ||= @user_id.to_s
      @acl_delete ||= @user_id.to_s
      @path = "" if @path.nil?
      @label_ids = ""
      @type = self.class.get_type_if_has_superclass
      @created_at = Time.now
      @updated_at = Time.now
      @created_by = @user_id
      @updated_by = @user_id
      @hidden ||= (self.class.hidden? ? true : false)
    end

    def set_attributes(attrs)
      set_default_attributes
      if attrs.is_a?(Hash) && attrs.keys.size > 0
        attrs.each_pair do |name, val|
          next if name == :type
          send(:"#{name}=", val)
        end
      end
    end

    def set_default_attributes
      @attributes ||= {}
      return unless self.class.db_setup_attributes
      self.class.db_setup_attributes.each_pair do |db_attr,val| 
        default_value = ((val.is_a?(Array) && val.size > 1 && val[1].is_a?(Hash) && val[1].has_key?(:default)) ? val[1][:default] : nil)
        @attributes[db_attr.to_sym] = default_value
        send(:"#{db_attr}=", default_value) if default_value
      end
    end

  end
end
