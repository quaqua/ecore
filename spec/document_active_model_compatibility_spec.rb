require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Document Active Model compatibility" do

  before(:all) do
    @user1_id = "1"
    Ecore::db.drop_table(:contacts) if Ecore::db.table_exists?(:contacts)
    class Contact
      include Ecore::DocumentResource
    end
    Contact.migrate
  end

  it "returns true, if document is a new record" do
    john = Contact.new(@user1_id)
    john.new_record?.should == true
  end

  it "returns false, if record has not been saved to repository yet" do
    john = Contact.new(@user1_id)
    john.persisted?.should == false
  end

end
