require 'active_support/inflector'
require 'sequel'
require 'securerandom'

module Ecore
  class Document

    def self.migrate
      Ecore::db.create_table :documents do
        column  :id, :string, :size => 8, :primary_key => true
        column  :type, :string, :null => false
        column  :name, :string, :null => false
        column  :acl_read, :string, :null => false
        column  :updated_at, :datetime, :null => false
        column  :path, :string, :null => false
        column  :position, :integer
        column  :updated_by, :string, :null => false
        column  :label_ids, :string
        column  :hidden, :boolean
        index :type
        index :name
        index :acl_read
        index :path
        index :updated_by
        index :updated_at
      end unless Ecore::db.table_exists?(:documents)
      Ecore::db.create_table :documents_trash do
        column  :id, :string, :size => 8, :primary_key => true
        column  :type, :string, :null => false
        column  :name, :string, :null => false
        column  :acl_read, :string, :null => false
        column  :updated_at, :datetime, :null => false
        column  :path, :string, :null => false
        column  :updated_by, :string, :null => false
        column  :deleted_at, :datetime, :null => false
        column  :deleted_by, :string, :null => false
        column  :label_ids, :string
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
      user_id = user_id_or_user.is_a?(String) ? user_id_or_user : user_id_or_user.id
      Ecore::db[:"documents#{"_trash" if options.delete(:trashed)}"].store_preconditions(user_id,nil,nil,nil,options)
    end

  end
end