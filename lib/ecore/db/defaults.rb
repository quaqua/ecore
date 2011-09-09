module Ecore
  module Orm
    # This module contains some helpers and handle schema (migrations):
    #
    # create_table :accounts do |t|
    #   t.ecore_node
    # end
    #
    # However this method does not add indexes. If you need them, here is the declaration:
    #
    # add_index "accounts", ["email"], :name => "email", :unique => true
    # add_index "accounts", ["confirmation_token"], :name => "confirmation_token", :unique => true
    # add_index "accounts", ["reset_password_token"], :name => "reset_password_token", :unique => true
    #
    module ActiveRecord
      module Schema
        def ecore_node
          column :id, :string, {:null => false, :primary => true, :limit => 36}
          column :path, :text
          column :name, :string, {:null => false}
          column :deleted_at, :datetime, {:default => nil}
          column :versions, :text
          column :label_node_ids, :text, :default => ""
          column :hashed_acl, :text
          column :starred, :boolean
          column :position, :integer
          column :updated_at, :datetime
          column :created_at, :datetime
          column :created_by, :string, :limit => 36
          column :updated_by, :string, :limit => 36
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::Table.send :include, Ecore::Orm::ActiveRecord::Schema
ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Ecore::Orm::ActiveRecord::Schema
