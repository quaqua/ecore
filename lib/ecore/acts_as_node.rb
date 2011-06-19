require File::expand_path "../node", __FILE__

require File::expand_path "../session", __FILE__
require File::expand_path '../node_array', __FILE__
require 'hooks'
require 'queries'
require 'acl'
require 'acl_extensions'
require 'labels'
require 'uuid_generator'

class << ActiveRecord::Base
  
  def acts_as_node( options={} )

    Ecore::Node.register name

    # overwrite default ActiveRecord first and find methods by passing session user
    # object and privileges to actual query
    extend Ecore::Queries

    include Ecore::AclExtensions
    include Ecore::Hooks
    include Ecore::Labels
    include Ecore::UUIDGenerator

    has_many :audits, :class_name => "Ecore::AuditLog", :as => :auditable
    belongs_to :creator, :class_name => "Ecore::User", :foreign_key => :created_by
    belongs_to :updater, :class_name => "Ecore::User", :foreign_key => :updated_by
    
    attr_accessor   :session, :audit_summary
    
    validates_presence_of :name
    
    before_create :setup_uuid, :setup_session_user_as_owner, :write_acl, :setup_created_by, :update_modifier
    before_update :check_write_permission, :write_acl, :update_modifier
    before_destroy :check_delete_permission
    
    # AUDIT
    after_create :audit_log_after_create
    after_update :audit_log_after_update
    after_destroy :audit_log_after_destroy, :unlink_labeled_nodes
    
  end
end
