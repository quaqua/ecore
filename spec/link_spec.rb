require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Document Links" do

  before(:all) do
    init_users_and_contact_class
  end

  before(:each) do
    Ecore::db[:contacts].delete
    Ecore::db[:"ecore/links"].delete
    Ecore::db[:"documents"].delete
  end

  it "creates a link to an existing node on repository root" do
    c1,c2 = create_contacts(2)
    link = c1.link_to(c2.absolute_path)
    link.class.should == Ecore::Link
  end

  it "links any attribute call to the original document" do
    c1,c2 = create_contacts(2)
    c1.link_to(c2.absolute_path)
    c1_link = c2.children.first
    c1_link.name.should == c1.name
    c1_link.firstname.should == c1.firstname
    c1_link.lastname.should == c1.lastname
  end

  it "saves changed attributes to the original document" do
    c1,c2 = create_contacts(2)
    link_id = c1.link_to(c2.absolute_path).id
    c1_link = Ecore::Document.find(@user1_id).where(:id => link_id).receive
    c1_link.firstname = 'firstname'
    c1_link.save.should == true
    c1.reload.firstname.should == 'firstname'
  end

  it "saves will load changes in original document on reload" do
    c1,c2 = create_contacts(2)
    link = c1.link_to(c2.absolute_path)
    link.name.should == c1.name
    c1.update(:firstname => 'other')
    link.firstname.should_not == c1.firstname
    link.reload.firstname.should == c1.firstname
  end

  it "will not change original's name if link name is changed" do
    c1,c2 = create_contacts(2)
    link = c1.link_to(c2.absolute_path)
    link.name = "different name"
    link.save
    c1.reload.name.should eq("c1")
    link.reload.name.should eq("different name")
  end

  it "will not affect original document if link is deleted" do
    c1,c2 = create_contacts(2)
    link = c1.link_to(c2.absolute_path)
    link.destroy.should == true
    Contact.find(@user1_id).where(:id => c1.id).receive.name.should == c1.name
  end

  it "will destroy link, if original document is destroyed" do
    c1,c2 = create_contacts(2)
    link = c1.link_to(c2.absolute_path)
    c1.destroy.should == true
    Ecore::Link.find(@user1_id).filter(:id => link.id).receive.should == nil
  end

  it "will return the original document's children" do
    c1,c2,c3,c4 = create_contacts(4)
    l1 = c1.link_to(c2.absolute_path)
    l1.children.size.should eq(0)
    c1.children.size.should eq(0)
    c1.children << c3
    c1.children << c4
    c1.children(:reload => true).size.should eq(2)
    l1.children(:reload => true).size.should eq(2)
  end

  it "returns all links this document is linked with" do
    c1,c2,c3,c4 = create_contacts(4)
    l1 = c1.link_to(c2.absolute_path).reload
    l2 = c1.link_to(c3.absolute_path).reload
    c1.links.size.should eq(2)
    c1.links.first.id.should eq(l1.id)
    c1.links.last.id.should eq(l2.id)
  end

  it "links to root level" do
    c1,c2 = create_contacts(2)
    link = c1.link_to("")
    Ecore::Document.find(@user1_id).filter(:id => link.id).receive.path.should eq("") 
  end

  it "adds numbering to document names, if link is created in same path as original document" do
    c1,c2 = create_contacts(2)
    link = c1.link_to("")
    link.name.should eq("#{c1.name} 1")
    link = c1.link_to("")
    link.name.should eq("#{c1.name} 2")
    link = c1.link_to("")
    link.name.should eq("#{c1.name} 3")
    Ecore::Document.find(@user1_id).filter(:id => link.id).receive.name.should eq("#{c1.name} 3")
  end

  it "will link to original document if linking to a link" do
    c1,c2 = create_contacts(2)
    link = c1.link_to(c2.absolute_path)
    link2 = link.link_to(c2.absolute_path)
    link2.orig_document_type.should eq(c1.class.name)
    link2.name.should eq("#{c1.name} 1")
    Ecore::Document.find(@user1_id).filter(:id => link2.id).receive.name.should eq("#{c1.name} 1")
  end

  it "will not keep any reference to linked link, if link from which has been linked is removed" do
    c1,c2 = create_contacts(2)
    link = c1.link_to(c2.absolute_path)
    link2 = link.link_to(c2.absolute_path)
    link.destroy.should eq(true)
    c1.links.size.should eq(1)
    Ecore::Document.find(@user1_id).filter(:id => link2.id).receive.name.should eq("#{c1.name} 1")
  end

end
