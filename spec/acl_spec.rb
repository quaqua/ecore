=begin
require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Ecore::Folder ACL" do

  before(:all) do
    Ecore::User.all.map(&:destroy)
    Ecore::Group.all.map(&:destroy)
    Folder.all.map(&:destroy)
    @mgr = Ecore::User.create(:name => 'manager', :password => 'mgr')
    @session = Ecore::Session.new(:name => 'manager', :password => 'mgr')
    @beta = Ecore::User.create(:name => 'beta', :password => 'beta')
    @g = Ecore::Group.create(:name => 'g')
    @g.add_user( @beta )
    @beta.session= Ecore::Session.new(:name => 'beta', :password => 'beta')
    @a = Folder.create(:name => 'a', :session => @session)
    @b = Folder.create(:name => 'b', :session => @session)
    @c = Folder.create(:name => 'c', :session => @session)
  end
  
  it "should return privileges for current node holder" do
    node = Folder.create(:name => 'aclnode', :session => @session)
    node.privileges.should == 'rwsd'
  end
  
  it "should return privileges for another user" do
    @a.privileges(@beta).should == nil
    @a.share( @beta, 'rw' ).should == true
    @a.privileges(@beta).should == 'rw'
  end
  
  it "should return effective_acl for current node holder" do
    @a.effective_acl[@mgr.uuid].privileges == 'rwsd'
  end
  
  it "should return effective_acl for user @beta" do
    @a.effective_acl[@beta.uuid].privileges = 'rw'
  end
  
  it "should unshare @beta from node @a" do
    @a.privileges(@beta).should == 'rw'
    @a.unshare( @beta )
    @a.privileges(@beta).should == nil
    @a.can_read?( @beta ).should == false
  end
  
  it "should share a node with @beta via Ecore::User.everybody" do
    @a.can_read?( @beta ).should == false
    @a.share( Ecore::User.everybody, 'r' )
    @a.save
    @a.can_read?( @beta ).should == true
    Folder.first(@beta.session, :uuid => @a.uuid).name.should == 'a'
  end
  
  it "should share a node with @beta via Ecore::User.anybody" do
    @a.unshare( Ecore::User.everybody )
    @a.save
    @a.can_read?( @beta ).should == false
    @a.share( Ecore::User.anybody, 'r' ).should == true
    @a.save
    @a.can_read?( @beta ).should == true
    @a.can_read?( Ecore::User.anybody ).should == true
  end
  
  it "should share a node with @beta via group @g" do
    @a.unshare( Ecore::User.anybody )
    @a.save
    @a.can_read?( @beta ).should == false
    @a.share( @g, 'rws' ).should == true
    @a.save
    @a.can_read?( @beta ).should == true
  end
  
  it "should share a node with @beta through inheritance and group membership" do
    @b.can_read?( @beta ).should == false
    @b.add_label( @a )
    @b.can_read?( @beta ).should == true
  end
  
  it "should show effective_acls for node @b and include inheritances" do
    @b.effective_acl.size.should == 2
    @b.effective_acl[@g.uuid].privileges.should == 'rws'
  end
  
  it "should show privileges and include inheritances in node @b for @beta" do
    @b.privileges(@beta) == 'rws'
  end
  
end
=end
