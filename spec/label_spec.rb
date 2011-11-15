require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Document Labels" do

  before(:all) do
    init_users_and_contact_class
  end

  before(:each) do
    Ecore::db[:contacts].delete
    Ecore::db[:labels].delete
    Ecore::db[:documents].delete
  end

  it "returns the document's labels" do
    c1 = create_contacts(1)[0]
    c1.labels.size.should == 0
  end

  it "creates a new label for a document" do
    c1 = create_contacts(1)[0]
    c1.add_label(:name => "l1")
    c1.save.should == true
    c1.labels.size.should == 1
    c1.labels.first.name.should == "l1"
  end

  it "removes a label from a document" do
    c1 = create_contacts(1)[0]
    c1.add_label(:name => "l1")
    c1.save.should == true
    c1 = Contact.find(@user1_id).where(:id => c1.id).receive
    c1.labels.size.should == 1
    c1.remove_label(:name => "l1")
    c1.save.should == true
    c1.labels.size.should == 0
  end

  it "will not create a label with the same name twice" do
    c1,c2,c3 = create_contacts(3)
    c1.add_label(:name => "l1")
    c2.add_label(:name => "l1")
    Ecore::Label.size.should == 1
  end

  it "finds a label by label name" do
    c1,c2 = create_contacts(2)
    c1.add_label(:name => "l1")
    labels = Ecore::Label.find(@user1_id, :name => "l1")
    labels.size.should == 1
    labels.first.class.should == Ecore::Label
  end

  it "lists all documents that have been labeled with label" do
    c1,c2,c3 = create_contacts(3)
    c1.add_label(:name => "l1")
    c2.add_label(:name => "l1")
    c1.save
    c2.save
    labels = Ecore::Label.find(@user1_id, :name => "l1")
    label_docs = labels.first.documents.receive(:all)
    label_docs.size.should == 2
    label_docs.first.class.should == Contact
  end

  it "lists all documents of type Contact labeled with label" do
    c1,c2,c3 = create_contacts(3)
    c1.add_label(:name => "l1")
    c2.add_label(:name => "l1")
    c1.save
    c2.save
    labels = Ecore::Label.find(@user1_id, :name => "l1")
    labels.first.documents.where(:type => "Contact").receive(:all).size.should == 2
  end

end
