require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Labels" do

  before(:all) do
    Folder.all.map(&:delete)
    Ecore::User.all.map(&:destroy)
    @alpha = Ecore::User.create!(:name => 'alpha', :password => 'alpha')
    @session = Ecore::Session.new(:name => 'alpha', :password => 'alpha')
    @a = Folder.create(:session => @session, :name => 'a')
    @b = Folder.create(:session => @session, :name => 'b')
    @c = Folder.create(:session => @session, :name => 'c')
  end

  it "should label folder @a with @b" do
    @a.labels.size.should == 0
    @a.add_label( @b )
    @a.save.should == true
    @a.labels.size.should == 1
    @a.labels.first.id.should== @b.id
  end

  it "should return @b as primary label of @a" do
    @a.primary_label.id.should == @b.id
  end

  it "should return @a as node of @b" do
    @b.nodes.first.id.should == @a.id
  end

  it "should add another node @c as a subnode of @b" do
    @b.add_label!( @c )
    @b.labels.size.should == 1
    @b.primary_label.id.should == @c.id
  end

  it "should return all ancestors of @a (@b and @c)" do
    @a.ancestors.size.should == 2
    @a.ancestors.first.id.should == @c.id
    @a.ancestors.last.id.should == @b.id
  end

  it "should prevent from looping @a -> @b -> @c -> @a -> ..." do
    @c.add_label( @a ).should == false
  end

  it "should not label node with itself" do
    @a.add_label( @a ).should == false
  end

  it "should remove label @c from label @b" do
    @b.labels.first.id.should == @c.id
    @b.remove_label!( @c )
    Folder.first(@session, :id => @b.id).labels.size.should == 0
  end

  it "should unlabel linked nodes if node is destroyed" do
    d = Folder.create(:session => @session, :name => 'd')
    @a.add_label!( d )
    @a.labels.size.should == 2
    @a.labels.first.id.should == @b.id
    @a.labels.last.id.should == d.id
    d.destroy
    @a.labels.size.should == 1
    @a.labels.first.id.should == @b.id
  end

end
