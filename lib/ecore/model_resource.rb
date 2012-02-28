# (c) 2012 by tastenwerk
# Author: quaqua@tastenwerk.com
#
require 'active_model' if defined?(Rails)

require File::expand_path("../attribute_methods", __FILE__)
require File::expand_path("../hooks", __FILE__)
require File::expand_path("../validations", __FILE__)
require File::expand_path("../active_model_layer", __FILE__)
require File::expand_path("../unique_id_generator", __FILE__)
require File::expand_path("../custom_transactions", __FILE__)

module Ecore

  #
  # a model can be used to get a database mapper object
  # with very similar syntax and functionality as an
  # Ecore::DocumentResource exclusive access management
  module ModelResource

    module ClassMethods

      # set up default attributes
      # like created_at, updated_at, ...
      #
      # valid options are
      #  * <tt>:hierarchy => true</tt> - creates a hierarchy attribute and loads hierarchy mixins (default: true)
      #  * <tt>:timestamps => true</tt> - skips the timestamp fileds (created_at, updated_at) (default: true)
      #  * <tt>:userstamps => true</tt> - skips created_by, updated_by and according methods (default: true)
      #  * <tt>:skip_audit => false</tt> - skips auditing for this model (default: false)
      #  * <tt>:labels => false</tt> - enables label support (default: false)
      #
      def default_attributes(options={})
        options[:timestamps] = true unless options.has_key?(:timestamps)
        options[:userstamps] = true unless options.has_key?(:userstamps)
        options[:hierarchy] = true unless options.has_key?(:hierarchy)
        @skip_audit = options[:skip_audit] ? options[:skip_audit] : false

        attribute :path, :string, :default => "" if options[:hierarchy]

        attribute :created_at, :datetime, :default => Time.now if options[:timestamps]
        attribute :created_by, :string if options[:userstamps]

        attribute :updated_at, :datetime if options[:timestamps]
        attribute :updated_by, :string if options[:userstamps]

        include Ecore::DocumentHierarchy if options[:hierarchy]
        include Ecore::LabelMixins if options[:labels]

      end

      # returns, if auditing is turned on or off for this
      # model
      def skip_audit?
        @skip_audit
      end

      # Default table_name to be used for Ecore
      def table_name
        return superclass.table_name if get_type_if_has_superclass
        name.underscore.pluralize.to_sym
      end

      # returns type of this class in case it has been 
      # derived from another Ecore::DocumentResource enabled class
      def get_type_if_has_superclass
        (defined?(superclass) && superclass.respond_to?(:table_name)) ? name : nil
      end

      # Invoke the database migration
      # done in the task
      #
      def migrate
        attrs = @db_setup_attributes || {}
        Ecore::db.create_table table_name do
          String  :id, :size => 8, :primary_key => true
          attrs.each_pair do |name, arr|
            column name, :text, arr[1] if arr[0] == :text
            String name, arr[1] if arr[0] == :string || arr[0] == String
            Fixnum name, arr[1] if arr[0] == :integer || arr[0] == Fixnum
            DateTime name, arr[1] if arr[0] == :datetime || arr[0] == DateTime
            Date name, arr[1] if arr[0] == :date || arr[0] == Date
            Time name, arr[1] if arr[0] == :time || arr[0] == Time
            Float name, arr[1] if arr[0] == :float || arr[0] == Float
            TrueClass name, arr[1] if arr[0] == :boolean || arr[0] == TrueClass || arr[0] == FalseClass
            TrueClass name, arr[1] if arr[0] == :bool
          end
        end unless Ecore::db.table_exists?(table_name)
      end

      # prepares a sequel dataset
      def find(user,filter_options=nil)
        user_id = user.id if user.is_a?(Ecore::User)
        user_id = user if user.is_a?(String)
        ds = Ecore::db[table_name].store_preconditions((user_id || Ecore::User.anybody_id),nil,nil,self,nil)
        filter_options ? ds.filter(filter_options) : ds
      end

      # creates a new dataset and saves it to the database
      # returns nil if saving was unsuccessful
      #
      def create(user,attrs)
        ds = new(user,attrs)
        ds if ds.save
      end

      # invokes create method but raises an Ecore::SavingFailed error
      # if save was unsuccessful
      #
      def create!(user,attrs)
        ds = create(user,attrs)
        raise Ecore::SavingFailed unless ds
        ds
      end

      # Counts the number of datasets by SQL COUNT method
      #
      def count
        Ecore::db[table_name].count
      end

    end

    include Ecore::ActiveModelLayer
    include Ecore::Validations::InstanceMethods
    include Ecore::CustomTransactions::InstanceMethods
    include Ecore::Hooks::InstanceMethods
    def self.included(model)
      model.extend Ecore::AttributeMethods
      model.extend ClassMethods
      model.extend Ecore::Hooks::ClassMethods
      model.extend Ecore::Validations::ClassMethods
      model.extend Ecore::CustomTransactions::ClassMethods
      model.extend Ecore::UniqueIDGenerator
      model.extend ActiveModel::Naming if defined?(Rails)
      @classes ||= []
      @classes.delete(model.name)
      @classes << model.name
    end

    def self.classes
      @classes
    end

    attr_reader :attributes, :orig_attributes, :changed_attributes
    attr_accessor :id, :acl_read, :acl_write, :acl_delete, :label_ids, :deleted_by, :deleted_at, :audit_save_action_name, :audit_name, :audit_summary

    # Initialize a new dataset with given
    # attributes. For available attributes see the
    # migrate class method
    # 
    def initialize(user,attrs={})
      @user_id = user.id if user.is_a?(Ecore::User)
      @user_id = user if user.is_a?(String)
      set_attributes(attrs)
    end

    # Overwrite default new_record? method
    # which is looking for a valid id.
    #
    def new_record?
      @id.nil? # @created_at.nil? # TODO: use case: skip timestamps ???
    end

    # save dataset to database
    def save(options={})
      success = false
      return false unless run_validations
      this_new_record = new_record?
      if new_record?
        run_hooks(:before,:create)
        run_hooks(:before,:save)
        @id = self.class.gen_unique_id
        init_default_attrs
        Ecore::db[self.class.table_name].insert(attributes.merge(:id => @id, :created_at => @created_at, :created_by => @user_id, :updated_by => @user_id))
        success = true
      else
        run_hooks(:before,:save)
        save_attrs = attributes.merge(:updated_at => Time.now, :updated_by => @user_id)
        save_attrs.delete(:created_at)
        save_attrs.delete(:id)
        Ecore::db[self.class.table_name].where(:id => @id).update(save_attrs)
        success = true
      end
      Ecore::Audit.log(@id, self.class.name, @path, audit_name, audit_save_action_name, (@user_id || Ecore::User.anybody_id)) if !options[:skip_audit] && !self.class.skip_audit?
      run_hooks(:after,:create) if this_new_record
      run_hooks(:after,:update) unless this_new_record
      run_hooks(:after,:save)
      success
    end

    # updates an entry with given attributes
    def update(attrs,options={})
      attrs.each_pair do |key, value|
        send("#{key}=",value)
      end
      save(options)
    end

    # deletes a datset
    def destroy
      return true if Ecore::db[self.class.table_name].filter(:id => @id).delete
      false
    end

    # returns the name which should be set when auditing
    # defaults to @audit_name or @name
    def audit_name
      @audit_name || @name
    end

    # returns the text which should be used to name
    # the action performed
    def audit_save_action_name
      @audit_save_action_name || "saved"
    end

    private

    def set_attributes(attrs)
      @attributes ||= {}
      if attrs.is_a?(Hash) && attrs.keys.size > 0
        attrs.each_pair do |name, val|
          next if name == :type
          send(:"#{name}=", val)
        end
      end
      @changed_attributes = nil
    end

    def init_default_attrs
      @path = "" if @path.nil?
      @label_ids = ""
      @type = self.class.get_type_if_has_superclass
      @created_at ||= Time.now
      @updated_at = Time.now
      @created_by = @user_id
      @updated_by = @user_id
    end


  end
end
