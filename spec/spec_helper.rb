require File::expand_path "../../lib/ecore", __FILE__

Ecore::Repository.init "spec/test-config-ecore.yml"

def create_contacts(num)
  arr = []
  (1..num).each do |i|
    arr << Contact.create!(@user1_id, :name => "c#{i}")
  end
  arr
end

class Contact
  include Ecore::DocumentResource
  default_attributes
end

def init_users_and_contact_class
  @user1_id = "1a"
  @user2_id = "2b"
  Ecore::db.drop_table(:contacts) if Ecore::db.table_exists?(:contacts)
  Contact.migrate
end
