require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Document Links" do

  before(:all) do
    init_users_and_contact_class
  end

  before(:each) do
    Ecore::db[:contacts].delete
    Ecore::db[:"ecore/links"].delete
  end

  it "creates a link to an existing node on repository root" do
    c1,c2 = create_contacts(2)
    link = c1.link_to(c2.absolute_path)
    link.class.should == Ecore::Link
  end

  it "doesn't create a link if given path == current path of document" do
    c1 = create_contacts(1)[0]
    lambda{ c1.link_to("") }.should raise_error(Ecore::LinkError, "cannot link to same path #{c1.path}==#{c1.path}")
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
    c1.update(:name => 'other')
    link.name.should_not == c1.name
    link.reload.name.should == c1.name
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

end
