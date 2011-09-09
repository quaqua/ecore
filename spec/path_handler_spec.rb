require ::File::expand_path( "../spec_helper", __FILE__ )

describe "PathHandler" do

  before(:all) do
    Folder.all.map(&:delete)
    Ecore::User.all.map(&:destroy)
    @alpha = Ecore::User.create!(:name => 'alpha', :password => 'alpha')
    @session = Ecore::Session.new(:name => 'alpha', :password => 'alpha')
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
    (@a.children << f).should == true
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

end
