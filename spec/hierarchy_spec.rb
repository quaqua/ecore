require ::File::expand_path( "../spec_helper", __FILE__ )

def create_tree(a,b,c,d,e)
  a.children.push(b)
  a.children.push(c)
  b.children.push(d)
  b.children.push(e)
end

describe "Document Hierarchy" do

  before(:all) do
    @user1_id = "1a"
    @user2_id = "2b"
    Ecore::db.drop_table(:contacts) if Ecore::db.table_exists?(:contacts)
    class Contact
      include Ecore::DocumentResource
    end
    Contact.migrate
  end

  before(:each) do
    Ecore::db[:contacts].delete
  end

  it "has an absolute_path method to show this document's full location in the repository including it's id" do
    c1 = create_contacts(1)[0]
    c1.absolute_path.should == "/#{c1.id}"
  end

  it "shows a document's children" do
    doc_a = create_contacts(1)[0]
    doc_a.children.size.should == 0
  end

  it "creates a child of document a" do
    doc_a = create_contacts(1)[0]
    child_a = doc_a.children.create(Contact, :name => 'child_a')
    child_a.class.should == Contact
    child_a.name.should == 'child_a'
    doc_a.children.size.should == 1
    doc_a.children.first.id.should == child_a.id
  end

  it "adds an existing child document to document a" do
    a,b = create_contacts(2)
    a.children.size.should == 0
    a.children.push(b).nil?.should == false
    a.children.size.should == 1
  end

  it "adds an existing document to a document via << method" do
    a,b = create_contacts(2)
    a.children.size.should == 0
    a.children << b
    a.children.size.should == 1
  end

  it "returns the child's parent_id" do
    a,b = create_contacts(2)
    a.children.push(b)
    b.reload.parent_id.should == a.id
    b.parent.id.should == a.id
  end

  it "returns the child's parent" do
    a,b = create_contacts(2)
    a.children.push(b)
    b.parent.id.should == a.id
  end

  it "creates a tree with depth=2" do
    a,b,c,d,e = create_contacts(5)
    create_tree(a,b,c,d,e)
    a.children.size.should == 2
    b.children.size.should == 2
    c.children.size.should == 0
    d.children.size.should == 0
    e.children.size.should == 0
  end

  it "finds only documents on the repository's root" do
    a,b,c,d,e = create_contacts(5)
    create_tree(a,b,c,d,e)
    root_contacts = Contact.find(@user1_id).where(:path => "").receive(:all)
    root_contacts.size.should == 1
  end

  it "only finds children meeting certain conditions" do
    a,b,c,d,e = create_contacts(5)
    create_tree(a,b,c,d,e)
    c2 = a.children(:get_dataset => true).where(:name => 'c2').receive
    c2.id.should == b.id
  end

  it "finds documents in any depth" do
    a,b,c,d,e = create_contacts(5)
    a.children << b
    b.children << c
    c.children << d
    d.children << e
    Contact.find(@user1_id).where(:path.like("#{a.absolute_path}%")).receive(:all).size.should == 4
  end

  it "finds a deep inside the hierarchy stored document's ancestors (ascending)" do
    a,b,c,d,e = create_contacts(5)
    a.children << b
    b.children << c
    c.children << d
    d.children << e
    e.ancestors.size.should == 4
    e.ancestors.first.id.should == a.id
  end

  it "finds ancestors in reversed order" do
    a,b,c,d,e = create_contacts(5)
    a.children << b
    b.children << c
    c.children << d
    d.children << e
    e.ancestors(:reverse).size.should == 4
    e.ancestors.first.id.should == d.id
  end

  it "moves a node to another parent" do
    a,b,c = create_contacts(3)
    a.children << b
    b.children << c
    b.children.size.should == 1
    c.reload.parent.id.should == b.id
    a.children.push(c)
    b.children(:reload => true).size.should == 0
    c.reload.parent.id.should == a.id
  end
    
  it "derives access definitions from parent" do
    a,b,c = create_contacts(3)
    a.share(@user2_id,'r')
    a.save
    a.reload
    a.children << b
    b.children << c
    c.reload.acl_read.should == a.acl_read
  end

  it "updates children if access for parent changes" do
    a,b,c = create_contacts(3)
    a.children << b
    b.children << c
    a.share(@user2_id,'r')
    a.save.should == true
    c.reload.acl_read.should == a.acl_read
    Contact.find(@user2_id).where(:id => c.id).receive.class.should == Contact
  end

  it "removes all children if parent is removed" do
    a,b,c = create_contacts(3)
    a.children << b
    b.children << c
    a.destroy.should == true
    Contact.find(@user1_id).where(:id => b.id).receive.should == nil
  end

  it "unshares all children, if sharing has changed" do
    a,b,c = create_contacts(3)
    a.children << b
    b.children << c
    a.share(@user2_id,'r')
    a.save.should == true
    c.reload.acl_read.should == a.acl_read
    Contact.find(@user2_id).where(:id => c.id).receive.class.should == Contact
    a.unshare(@user2_id)
    a.save
    Contact.find(@user2_id).where(:id => c.id).receive.should == nil
  end

  it "moves one child to another parent" do
    a,b,c = create_contacts(3)
    a.children << b
    b.path.should == "/#{a.id}"
    b.parent_id = c.id
    b.save.should == true
    b.reload.path.should == "/#{c.id}"
  end

  it "moves one child to another parent through update method" do
    a,b,c = create_contacts(3)
    a.children << b
    b.path.should == "/#{a.id}"
    Contact.find(@user1_id).where(:id => b.id).receive.path.should == "/#{a.id}"
    b.update(:parent_id => c.id).should == true
    b.reload.path.should == "/#{c.id}"
    Contact.find(@user1_id).where(:id => b.id).receive.path.should == "/#{c.id}"
  end

  it "moves child with all subchilds to another document" do
    a,b,c,d,e = create_contacts(5)
    a.children << b
    b.children << c
    c.children << d
    b.path.should == "/#{a.id}"
    c.path.should == "/#{a.id}/#{b.id}"
    d.path.should == "/#{a.id}/#{b.id}/#{c.id}"
    b.update(:parent_id => e.id).should == true
    b.reload.path.should == "/#{e.id}"
    c.reload.path.should == "/#{e.id}/#{b.id}"
    d.reload.path.should == "/#{e.id}/#{b.id}/#{c.id}"
  end

end
