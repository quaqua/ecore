require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Document ACCESS CONTROL" do

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

  it "grants access to creator by default" do
    c1 = create_contacts(1)[0]
    c1.can_read?(@user1_id).should == true
    c1.can_read?.should == true
  end

  it "denies access to anybody else but creator" do
    c1 = create_contacts(1)[0]
    c1.can_read?(@user2_id).should == false
    c1.can_write?(@user2_id).should == false
    c1.can_delete?(@user2_id).should == false
    Contact.find(@user2_id).receive(:all).size.should == 0
  end

  it "shares a document with user2 read only" do
    c1,c2 = create_contacts(2)
    c1.can_read?(@user2_id).should == false
    c1.share(@user2_id,'r').should == true
    c1.can_read?(@user2_id).should == true
    c1.can_write?(@user2_id).should == false
    c1.can_delete?(@user2_id).should == false
  end

  it "shares a document with user2 read/write" do
    c1,c2 = create_contacts(2)
    c1.can_read?(@user2_id).should == false
    c1.share(@user2_id,'rw').should == true
    c1.can_read?(@user2_id).should == true
    c1.can_write?(@user2_id).should == true
    c1.can_delete?(@user2_id).should == false
  end

  it "shares a document with user2 read/write/delete" do
    c1,c2 = create_contacts(2)
    c1.can_read?(@user2_id).should == false
    c1.share(@user2_id,'rwd').should == true
    c1.can_read?(@user2_id).should == true
    c1.can_write?(@user2_id).should == true
    c1.can_delete?(@user2_id).should == true
  end

  it "doesn't allow a user with read access to share an object" do
    c1,c2 = create_contacts(2)
    c1.can_read?(@user2_id).should == false
    c1.share(@user2_id,'r').should == true
    c1.save.should == true
    Contact.find(@user2_id).receive.share(0,'r').should == false
  end

  it "won't display an object to which a user doesn't have access" do
    c1,c2 = create_contacts(2)
    Contact.find(@user2_id).receive.should == nil
  end

  it "unshares a document with user2" do
    c1 = create_contacts(1)[0]
    c1.share(@user2_id) # 'rw' is default
    c1.save.should == true
    Contact.find(@user2_id).where(:id => c1.id).receive.class.should == Contact
    c1.unshare(@user2_id).should == true
    c1.save.should == true
    Contact.find(@user2_id).where(:id => c1.id).receive.should == nil
  end

  it "shares a document with anybody user" do
    c1 = create_contacts(1)[0]
    c1.share(Ecore::User.anybody)
    c1.save.should == true
    c1 = Contact.find(@user1_id).where(:id => c1.id).receive
    c1.can_read?(Ecore::User.anybody).should == true
  end

  it "shares a document with anybody and along with any user" do
    c1 = create_contacts(1)[0]
    c1.share(Ecore::User.anybody)
    c1.save.should == true
    c1 = Contact.find(@user1_id).where(:id => c1.id).receive
    c1.can_read?(@user2_id).should == true
    Contact.find(@user2_id).where(:id => c1.id).receive.name.should == c1.name
  end

  it "shares a document with all members of a group" do
    Ecore::db[:users].delete
    g1 = Ecore::Group.create(@user1_id, :name => "g1")
    u1 = Ecore::User.create(@user1_id, :name => "u1", :password => 'p1')
    u2 = Ecore::User.create(@user1_id, :name => "u2", :password => 'p2')
    u1.add_group!(g1)
    u2.add_group!(g1)
    c1 = Contact.create(u1.id, :name => 'c1')
    c1.share!(g1).should == true
    Contact.find(u2.id_and_group_ids).where(:name => 'c1').receive.class.should == Contact
  end

  it "will allways remove acl_write/acl_delete for anybody user automatically" do
    c1,c2,c3 = create_contacts(3)
    c1.share!(Ecore::User.anybody_id)
    c1.children << c2
    c2.children << c3
    c3.acl_read.include?(Ecore::User.anybody_id).should == true
    c3.acl_write.include?(Ecore::User.anybody_id).should == false
    c3.acl_delete.include?(Ecore::User.anybody_id).should == false
    Contact.find(Ecore::User.anybody_id).receive.acl_write.include?(Ecore::User.anybody_id).should == false
    Contact.find(Ecore::User.anybody_id).receive.acl_delete.include?(Ecore::User.anybody_id).should == false
  end

  it "will remove acl_write/acl_delete for anybody in any circumstance" do
    c1 = create_contacts(1)[0]
    c1.acl_write = c1.acl_write << ",#{Ecore::User.anybody_id}"
    c1.acl_write.should == "#{@user1_id},#{Ecore::User.anybody_id}"
    c1.save.should == true
    c1.acl_write.should == @user1_id
    c1.acl_delete.should == @user1_id
  end

end
