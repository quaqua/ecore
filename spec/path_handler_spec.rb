require ::File::expand_path( "../spec_helper", __FILE__ )

describe "PathHandler" do

  before(:all) do
    Folder.all.map(&:delete)
    Ecore::User.all.map(&:destroy)
    @alpha = Ecore::User.create!(:name => 'alpha', :password => 'alpha')
    @session = Ecore::Session.new(:name => 'alpha', :password => 'alpha')
    @beta = Ecore::User.create!(:name => 'beta', :password => 'beta')
    @a = Folder.create(:session => @session, :name => 'a')
    @b = Folder.create(:session => @session, :name => 'b')
    @c = Folder.create(:session => @session, :name => 'c')
  end

  it "should automatically create a path == '/' for a new node" do
    f = create_folder("f1")
    f.path.should == "/"
  end

  it "should make the new folder child of @a" do
    f = create_folder("f2")
    @a.children.size.should == 0
    @a.add_child(f).should == true
    f = Folder.first(@session, :id => f.id)
    f.parent.id.should == @a.id
    @a.children.size.should == 1
  end

  it "should make the new folder a child of @a (via parent method)" do
    f = create_folder("f3")
    f.parent.should == nil
    f.parent = @a
    f.save
    f.parent.id.should == @a.id
  end
  
  it "moves a node path" do
    f4 = create_folder('f4')
    f5 = create_folder('f5')
    f6 = create_folder('f6')
    f6beta = Folder.find( Ecore::Session.new(:name => 'beta', :password => 'beta'), :id => f6 ).size.should == 0
    f4.share(@beta,'rwsd')
    f4.add_child f5
    f5.add_child f6
    f6beta = Folder.find( Ecore::Session.new(:name => 'beta', :password => 'beta'), :id => f6 ).size.should == 1
  end
  
  it "returns parent also as a label" do
    f7 = create_folder("f7")
    f8 = create_folder("f8")
    f7.add_child(f8)
    f7.nodes.size.should == 1
    f8.labels.first.id.should == f7.id
  end
  
  it "also removes path if label was removed" do
    f9 = create_folder("f9")
    f10 = create_folder("f10")
    f9.add_child(f10).should == true
    f10.labels.first.id.should == f9.id
    f10.path.should == "#{f9.path}#{f9.id}/"
    f10.remove_label(f9).should == true
    f10.labels.size.should == 0
    f10.path.should == "/"
    
  end

end
