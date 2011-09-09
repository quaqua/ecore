require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Labels ACL" do

  before(:all) do
    Folder.all.map(&:delete)
    Ecore::User.all.map(&:destroy)
    @alpha = Ecore::User.create!(:name => 'alpha', :password => 'alpha')
    @beta = Ecore::User.create!(:name => 'beta', :password => 'beta')
    @beta_session = Ecore::Session.new(:name => 'beta', :password => 'beta')
    @session = Ecore::Session.new(:name => 'alpha', :password => 'alpha')
    @a = Folder.create(:session => @session, :name => 'a')
    @b = Folder.create(:session => @session, :name => 'b')
    @c = Folder.create(:session => @session, :name => 'c')
  end

  it "should share node @a with @beta and share all it's labeled nodes along with it" do
    @b.add_label!( @a )
    @a.share!( @beta, 'r' )
    Folder.first(@session, :id => @b.id).can_read?( @beta ).should == true
    Folder.first(@beta_session, :id => @b.id).id.should == @b.id
  end

  it "should unshare a node from being shared" do
    @a.unshare!( @beta )
    Folder.first(@session, :id => @b.id).can_read?( @beta ).should == false
    Folder.first(@beta_session, :id => @b.id).should == nil
  end

  it "should share node @a with beta and pass on permissions through @b to @c" do
    @a << @b # done already
    @b << @c
    @a.share!( @beta, 'rwsd' )
    Folder.first(@beta_session, :id => @c.id).id.should == @c.id
  end

  it "should copy over acl when being created with :parent_node_id attribute" do
    @a.acl.size.should == 2
    d = Folder.create(:session => @session, :parent_node_id => @a.id, :name => 'd')
    d.acl.size.should == 2
  end

  it "should copy over acl when being labeled with something" do
    e = Folder.create(:session => @session, :name => 'e')
    e.acl.size.should == 1
    e.add_label!( @a )
    e.acl.size.should == 2
    Folder.first(@beta_session, :name => 'e').id.should == e.id
  end

  it "should remove acl when being unlabeled" do
    e = Folder.first(@session, :name => 'e')
    e.acl.size.should == 2
    e.remove_label!( @a )
    e.acl.size.should == 1
    Folder.first(@beta_session, :name => 'e').should == nil
  end

  it "should prevent acle form other labels when one label was removed" do
    e = Folder.first(@session, :name => 'e')
    @a << e
    @b << e
    e.acl.size.should == 2
    e.remove_label!( @a )
    e.acl.size.should == 2
    Folder.first(@beta_session, :name => 'e').id.should == e.id
  end

end
