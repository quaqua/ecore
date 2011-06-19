require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Ecore::Node" do

  before(:all) do
    Folder.all.map(&:delete)
    Ecore::User.all.map(&:destroy)
    @alpha = Ecore::User.create!(:name => 'alpha', :password => 'alpha')
    @session = Ecore::Session.new(:name => 'alpha', :password => 'alpha')
    @f = Folder.create!(:session => @session, :name => 'test')
  end

  it "should find a folder via the Ecore::Node.first method" do
    Ecore::Node.first(@session, :name => @f.name).id.should == @f.id
  end

  it "should find a folder via the Ecore::Node.find method" do
    Ecore::Node.find(@session, :name => @f.name).first.id.should == @f.id
  end

end
