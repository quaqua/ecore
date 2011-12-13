require ::File::expand_path( "../spec_helper", __FILE__ )

def create_contacts(num)
  arr = []
  (1..num).each do |i|
    arr << Contact.create!(@user1_id, :name => "c#{i}")
  end
  arr
end

describe "Document main functionality" do

  before(:all) do
    @user1_id = "1a"
    Ecore::db.drop_table(:contacts) if Ecore::db.table_exists?(:contacts)
    Ecore::db.drop_table(:contacts_trash) if Ecore::db.table_exists?(:contacts_trash)
    Ecore::db.drop_table(:documents) if Ecore::db.table_exists?(:documents)
    Ecore::db.drop_table(:documents_trash) if Ecore::db.table_exists?(:documents_trash)
    Ecore::Document.migrate
    class Contact
      include Ecore::DocumentResource
      attribute :firstname, :string
      attribute :lastname, :string
    end
    Contact.migrate
  end

  before(:each) do
    Ecore::db[:contacts].delete
    Ecore::db[:contacts_trash].delete if Ecore::db.table_exists?(:contacts_trash)
    Ecore::db[:documents].delete
    Ecore::db[:documents_trash].delete
  end

  it "creates a new contact but doesn't save it yet" do
    john = Contact.new(@user1_id, :name => 'John')
    john.is_a?(Contact).should == true
    john.new_record?.should == true
  end

  it "does not save the contact unless all validations are met" do
    john = Contact.new(@user1_id)
    john.save.should == false
    john.errors.should == {:name => ['required']}
  end

  it "creates a new contact and saves it to the database" do
    Ecore::db[:contacts].count.should == 0
    john = Contact.new(@user1_id, :name => 'John')
    john.save.should == true
    Ecore::db[:contacts].count.should == 1
    Ecore::db[:contacts].first[:name].should == 'John'
  end

  it "creates with create method" do
    Ecore::db[:contacts].count.should == 0
    john = Contact.create(@user1_id, :name => 'John')
    Ecore::db[:contacts].count.should == 1
  end

  it "sets up creator after saving" do
    Ecore::db[:contacts].count.should == 0
    john = Contact.create(@user1_id, :name => 'John')
    john.reload.created_by.should == @user1_id
  end

  it "creates contact with create!" do
    Ecore::db[:contacts].count.should == 0
    john = Contact.create!(@user1_id, :name => 'John')
    Ecore::db[:contacts].count.should == 1
  end

  it "raises error if create! is used and save method fails" do
    Ecore::db[:contacts].count.should == 0
    lambda{ Contact.create!(@user1_id) }.should raise_error(Ecore::SavingFailed)
    Ecore::db[:contacts].count.should == 0
  end

  it "adds db-id if saving was successful" do
    john = Contact.create!(@user1_id, :name => 'John')
    john.id.size.should == 8 
  end

  it "is not a new_record? any more after creation was successful" do
    john = Contact.new(@user1_id, :name => 'John')
    john.new_record?.should == true
    john.save.should == true
    john.new_record?.should == false
  end

  it "still is a new_record? if save method fails" do
    john = Contact.new(@user1_id)
    john.save.should == false
    john.new_record?.should == true
  end

  it "creates a document entry along with contact" do
    Ecore::db[:contacts].count.should == 0
    Ecore::db[:documents].count.should == 0
    john = Contact.create!(@user1_id, :name => 'test')
    Ecore::db[:contacts].count.should == 1
    Ecore::db[:documents].count.should == 1
    Ecore::db[:documents].first[:id].should == Ecore::db[:contacts].first[:id]
    Ecore::db[:documents].first[:type].should == john.class.name
  end

  it "creates acl entries for creator" do
    john = Contact.new(@user1_id, :name => 'test')
    john.can_read?.should == false
    john.can_write?.should == false
    john.can_delete?.should == false
    john.save.should == true
    john.can_read?.should == true
    john.can_write?.should == true
    john.can_delete?.should == true
  end

  it "finds a document" do
    orig_john = Contact.create!(@user1_id, :name => 'john')
    john = Contact.find(@user1_id).where(:name => 'john').receive
    john.id.should == orig_john.id
  end

  it "finds a subclassed document" do
    class Employee < Contact
    end
    orig_emp = Employee.create!(@user1_id, :name => 'john')
    Contact.find(@user1_id).where(:name => 'john').receive.id.should == orig_emp.id
    Contact.find(@user1_id).where(:name => 'john').receive.is_a?(Contact).should == true
    Contact.find(@user1_id).where(:name => 'john').receive.is_a?(Employee).should == true
  end

  it "finds all matching documents and returns an array" do
    c1,c2,c3 = create_contacts(3)
    e1 = Employee.create!(@user1_id, :name => 'e1')
    Contact.find(@user1_id).receive(:all).size.should == 4
    Employee.find(@user1_id).receive(:all).size.should == 1
  end

  it "finds all matching documents with conditions" do
    c1,c2,c3 = create_contacts(3)
    Contact.find(@user1_id).where(:name.like('c%')).receive(:all).size.should == 3
  end

  it "changes and saves document's name" do
    c1 = create_contacts(1)[0]
    c1.name.should == 'c1'
    c1.name = 'o1'
    c1.attributes[:name].should == 'o1'
    c1.save.should == true
    Contact.find(@user1_id).receive.name.should == 'o1'
  end

  it "updates multiple attributes with the update method and saves document to repository" do
    c1 = create_contacts(1)[0]
    c1.update(:name => 'o1', :lastname => 'b', :firstname => 'c')
    c1 = Contact.find(@user1_id).receive
    c1.name.should == 'o1'
    c1.firstname.should == 'c'
    c1.lastname.should == 'b'
  end

  it "removes a document from the repository" do
    c1,c2 = create_contacts(2)
    Ecore::db[:documents].count.should == 2
    Ecore::db[:contacts].count.should == 2
    c1.destroy.should == true
    Ecore::db[:documents].count.should == 1
    Ecore::db[:contacts].count.should == 1
  end

  it "migrates contact class with :trash option" do
    Contact.migrate(:trash => true)
    Ecore::db.table_exists?(:contacts_trash).should == true
  end

  it "trashes a document (if class has _trash table)" do
    c1,c2 = create_contacts(2)
    Ecore::db[:documents].count.should == 2
    Ecore::db[:contacts].count.should == 2
    Ecore::db[:contacts_trash].count.should == 0
    Ecore::db[:documents_trash].count.should == 0
    c1.destroy.should == true
    Ecore::db[:documents].count.should == 1
    Ecore::db[:contacts].count.should == 1
    Ecore::db[:contacts_trash].count.should == 1
    Ecore::db[:documents_trash].count.should == 1
  end

  it "lists trashed documents" do
    c1 = create_contacts(1)[0]
    c1.destroy.should == true
    c1 = Ecore::Document.find(@user1_id, :trashed => true).receive
    c1.is_a?(Contact).should == true
    c1.trashed?.should == true
  end

  it "finds a specific document in trash" do
    c1 = create_contacts(1)[0]
    c1.destroy.should == true
    Ecore::Document.find(@user1_id, :trashed => true).where(:name => c1.name).receive.id.should == c1.id
  end

  it "also finds documents by using Class' find method" do
    c1 = create_contacts(1)[0]
    c1.destroy.should == true
    Contact.find(@user1_id, :trashed => true).where(:id => c1.id).receive.name.should == c1.name
  end

  it "permantly deletes a document from the trash" do
    c1 = create_contacts(1)[0]
    c1.destroy.should == true
    c1 = Contact.find(@user1_id, :trashed => true).where(:id => c1.id).receive
    c1.trashed?.should == true
    c1.destroy.should == true
    Contact.find(@user1_id, :trashed => true).where(:id => c1.id).receive.should == nil
  end

  it "restores a document" do
    c1 = create_contacts(1)[0]
    Ecore::db[:contacts].count.should == 1
    Ecore::db[:contacts_trash].count.should == 0
    c1.destroy.should == true
    Ecore::db[:contacts].count.should == 0
    Ecore::db[:contacts_trash].count.should == 1
    Contact.find(@user1_id).where(:id => c1.id).receive.should == nil
    c1 = Contact.find(@user1_id, :trashed => true).where(:id => c1.id).receive
    c1.restore.should == true
    Ecore::db[:contacts].count.should == 1
    Ecore::db[:contacts_trash].count.should == 0
    Contact.find(@user1_id).where(:id => c1.id).receive.name.should == c1.name
  end

  it "reloads a document's data from the repository" do
    a = create_contacts(1)[0]
    Ecore::db[:contacts].where(:id => a.id).update(:name => 'dd')
    a.name.should == 'c1'
    a.reload
    a.name.should == 'dd'
  end

  it "shows changed attributes in a changed_attributes accessor" do
    a = create_contacts(1)[0]
    a.changed_attributes.should == nil
    a.name = 'other'
    a.changed_attributes.should == {:name => 'other'}
  end

  it "finds a document by providing a new user object" do
    u1 = Ecore::User.first(:name => "uu1") || Ecore::User.create("1a", :name => 'uu1', :password => 'pu1')
    c1 = Contact.create(u1, :name => 'c1')
    Ecore::Document.find(u1).filter(:name => 'c1').receive.id.should == c1.id
  end

  it "skips hooks in destroy method" do
    class Contact
      include Ecore::DocumentResource
      attribute :firstname, :string
      attribute :lastname, :string
      before :destroy, :set_firstname
      
      def set_firstname
        self.firstname = "fn"
      end
    end
    c0,c1 = create_contacts(2)
    c0.destroy.should eq(true)
    c0.firstname.should eq("fn")
    c1.firstname = "firstname"
    c1.destroy(:skip_hooks => true).should eq(true)
    c1.firstname.should eq("firstname")
  end

  it "skips auditing in save method" do
    c0 = create_contacts(1)[0]
    audit_count = Ecore::db[:audits].count
    c0.save
    Ecore::db[:audits].count.should eq(audit_count+1)
    c0.save(:skip_audit => true)
    Ecore::db[:audits].count.should eq(audit_count+1)
  end
    
end
