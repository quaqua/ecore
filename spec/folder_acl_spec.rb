require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Folder ACL" do

  before(:all) do
    Folder.all.map(&:delete)
    Ecore::User.all.map(&:destroy)
    Ecore::Group.all.map(&:destroy)
    @alpha = Ecore::User.create!(:name => 'alpha', :password => 'alpha')
    @beta = Ecore::User.create!(:name => 'beta', :password => 'beta')
    @alphabetagroup = Ecore::Group.create!(:name => 'alphabeta')
    @alphabetagroup << @alpha
    @alphabetagroup << @beta
    @session = Ecore::Session.new(:name => 'alpha', :password => 'alpha')
    @beta_session = Ecore::Session.new(:name => 'beta', :password => 'beta')
  end

  it "should setup permissions for the node's creater" do
    f = Folder.new(:name => 'test', :session => @session)
    f.save.should == true
    f.acl[@session.user.id].privileges.should == 'rwsd'
  end

  it "should find the node according to the stored privileges" do
    Folder.first(@session, :name => 'test').class.should == Folder
    Folder.first(Ecore::Session.new(:name => 'anybody'), :name => 'test').class.should == NilClass
    Folder.first(@beta_session, :name => 'test').class.should == NilClass
  end

  it "should return if user can read the node" do
    f = Folder.first(@session, :name => 'test')
    f.can_read?.should == true
    f.can_read?(Ecore::User.anybody).should == false
    f.can_read?(@beta).should == false
  end

  it "should return if user can write the node" do
    f = Folder.first(@session, :name => 'test')
    f.can_write?.should == true
    f.can_write?(Ecore::User.anybody).should == false
    f.can_write?(@beta).should == false
  end

  it "should return if user can share the node" do
    f = Folder.first(@session, :name => 'test')
    f.can_share?.should == true
    f.can_share?(Ecore::User.anybody).should == false
    f.can_share?(@beta).should == false
  end

  it "should return if user can delete the node" do
    f = Folder.first(@session, :name => 'test')
    f.can_delete?.should == true
    f.can_delete?(Ecore::User.anybody).should == false
    f.can_delete?(@beta).should == false
  end

  it "should share a node with user beta" do
    f = Folder.first(@session, :name => 'test')
    f.can_read?(@beta).should == false
    f.share( @beta, 'r' )
    f.can_read?(@beta).should == true
    f.can_write?(@beta).should == false
    f.can_share?(@beta).should == false
    f.can_delete?(@beta).should == false
    f.save.should == true
    f = Folder.first(@beta_session, :name => 'test')
    f.class.should == Folder
    lambda{ f.update_attributes(:name => 'test2') }.should raise_error(Ecore::SecurityTransgression)
  end

  it "should unshare a node" do
    f = Folder.first(@session, :name => 'test')
    f.can_read?(@beta).should == true
    f.unshare( @beta ).should == true
    f.save.should == true
    f.can_read?(@beta).should == false
    Folder.first(@beta_session, :name => 'test').should == nil
  end

  it "should share a node with user anybody" do
    f = Folder.first(@session, :name => 'test')
    f.can_read?(@beta).should == false
    f.share!( Ecore::User.anybody, 'r' ).should == true
    f.can_read?(Ecore::User.anybody).should == true
    f.can_read?(@beta).should == true
    Folder.first(@beta_session, :name => 'test').name.should == 'test'
    Folder.first(Ecore::Session.new(:name => 'anybody'), :name => 'test').name.should == 'test'
    f.unshare!(Ecore::User.anybody).should == true
  end

  it "should share a node with user everybody and make it visible for user @beta" do
    f = Folder.first(@session, :name => 'test')
    f.can_read?(@beta).should == false
    f.can_read?(Ecore::User.anybody).should == false
    f.share!( Ecore::User.everybody, 'r' ).should == true
    f.can_read?(@beta).should == true
    f.can_read?(Ecore::User.anybody).should == false
    Folder.first(@beta_session, :name => 'test').name.should == 'test'
    Folder.first( Ecore::Session.new(:name => 'anybody'), :name => 'test' ).should == nil
    f.unshare!( Ecore::User.everybody ).should == true
  end

  it "should share a node with alphabetagroup and pass on access to @beta" do
    f = Folder.first(@session, :name => 'test')
    f.can_read?(@alphabetagroup).should == false
    f.share!( @alphabetagroup, 'rw' ).should == true
    f = Folder.first(@beta_session, :name => 'test')
    f.can_write?.should == true
    f.update_attributes(:name => 'test2').should == true
    lambda{ f.destroy }.should raise_error(Ecore::SecurityTransgression)
    f.can_read?(Ecore::User.anybody).should == false
    f.share!( Ecore::User.anybody, 'r' ).should == nil
    f.can_read?(Ecore::User.anybody).should == false
    f = Folder.first(@session, :name => 'test2')
    f.update_attributes(:name => 'test').should == true
  end

  it "should not allow anybody to get more privileges than read only" do
    f = Folder.first(@session, :name => 'test')
    lambda { f.share!( Ecore::User.anybody, 'rw' ) }.should raise_error(Ecore::PrivilegesTransgression)
    lambda { f.share!( Ecore::User.anybody, 'rws' ) }.should raise_error(Ecore::PrivilegesTransgression)
    lambda { f.share!( Ecore::User.anybody, 'rwsd' ) }.should raise_error(Ecore::PrivilegesTransgression)
    lambda { f.share!( Ecore::User.anybody, 'd' ) }.should raise_error(Ecore::PrivilegesTransgression)
  end

end
