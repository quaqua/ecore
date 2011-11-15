require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Document Array" do

  before(:all) do
    @user1_id = "1a"
    @user2_id = "2b"
    Ecore::db.drop_table(:contacts) if Ecore::db.table_exists?(:contacts)
    class Contact
      include Ecore::DocumentResource
    end
    Contact.migrate
  end

  it "buildes a new document array" do
    c1 = create_contacts(1)[0]
    Ecore::DocumentArray.new(c1,[]).class.should == Ecore::DocumentArray
  end

  it "raises an error if non-document object is passed to create" do
    c1 = create_contacts(1)[0]
    da = Ecore::DocumentArray.new(c1,[])
    da.class.should == Ecore::DocumentArray
    lambda{ da.create("this",'that') }.should raise_error(TypeError)
  end
end
