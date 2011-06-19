require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Folder" do

  before(:all) do
    Folder.all.map(&:delete)
    Ecore::User.all.map(&:destroy)
    @alpha = Ecore::User.create!(:name => 'alpha', :password => 'alpha')
    @session = Ecore::Session.new(:name => 'alpha', :password => 'alpha')
  end

  it "should initialize and save a new Folder" do
    f = Folder.new(:session => @session, :name => 'test')
    f.save.should == true
  end

  it "should create a new folder" do
    Folder.create(:session => @session, :name => 'test')
    Folder.first(@session, :name => 'test').name.should == 'test'
  end

  it "should not create a new folder without name given" do
    f = Folder.new(:session => @session)
    f.save.should == false
    f.errors[:name] == "can't be blank"
  end

  it "should not create a new folder without a valid session" do
    f = Folder.new(:name => 'test')
    lambda{ f.save }.should raise_error(Ecore::MissingSession)
  end

  it "should generate a unique id for the folder" do
    f = Folder.new(:name => 'test', :session => @session)
    f.save.should == true
    f.id.class.should == String
    f.id.size.should == 36
  end

  it "should update node's attributes" do
    f = Folder.first(@session, :name => 'test')
    f.update_attributes(:name => 'test2')
    Folder.first(@session, :id => f.id).name.should == 'test2'
  end

  it "should setup creator" do
    f = Folder.create(:session => @session, :name => 'test')
    f.creator.id.should == @session.user.id
  end

  it "should setup updater" do
    f = Folder.find(@session, :name => 'test').first
    f.updater.id.should == @session.user.id
    f.update_attributes(:name => 'test2').should == true
    f.updater.id.should == @session.user.id
  end

end
