require 'active_support/inflector'
require 'sequel'
require 'securerandom'

module Ecore
  class Document

    def self.migrate
      Ecore::db.create_table :documents do
        String  :id, :size => 8, :primary_key => true
        String  :type, :null => false
        String  :name, :null => false
        String  :acl_read, :null => false
        column  :updated_at, :datetime, :null => false
        String  :path, :null => false
        column  :position, :integer
        String  :updated_by, :null => false
        String  :label_ids, :default => ""
        String  :tags, :default => ""
        String  :link_type
        column  :starred, :boolean, :default => false
        column  :hidden, :boolean
        index :type
        index :link_type
        index :name
        index :acl_read
        index :path
        index :updated_by
        index :updated_at
        index :label_ids
        index :tags
      end unless Ecore::db.table_exists?(:documents)
      Ecore::db.create_table :documents_trash do
        String  :id, :size => 8, :primary_key => true
        String  :type, :null => false
        String  :name, :null => false
        String  :acl_read, :null => false
        column  :updated_at, :datetime, :null => false
        String  :path, :null => false
        String  :updated_by, :null => false
        column  :deleted_at, :datetime, :null => false
        column  :starred, :boolean, :default => false
        String  :deleted_by, :null => false
        String  :label_ids, :default => ""
        String  :tags, :default => ""
        String  :link_type
        column  :hidden, :boolean
        column  :position, :integer
        index :type
        index :name
        index :acl_read
        index :path
        index :deleted_by
        index :deleted_at
      end unless Ecore::db.table_exists?(:documents_trash)
    end

    # looks up a document in the database
    # options:
    #
    # * <tt>:trashed</tt> - lookup in document's trash table (if configured)
    # * <tt>:hidden</tt> - also include hidden douments in lookup
    #
    def self.find(user_id_or_user, options={:trashed => false, :hidden => false})
      Ecore::db[:"documents#{"_trash" if options.delete(:trashed)}"].store_preconditions(user_id_or_user,nil,nil,nil,options)
    end

  end
end
