require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Users and Groups" do

  before(:each) do
    Ecore::db[:users].delete
    @user1_id = "1a"
    @u1 = Ecore::User.create(@user1_id, :name => 'u1', :password => 'p1')
    @g1 = Ecore::Group.create(@user1_id, :name => 'g1')
  end

  it "initializes a new user object but doesn't save it yet" do
    user1 = Ecore::User.new(@user1_id, :name => 'user1')
    user1.class.should == Ecore::User
  end

  it "sets name and password attributes for user" do
    user1 = Ecore::User.new(@user1_id, :name => 'user1', :password => 'pass1')
    user1.name.should == 'user1'
    user1.password.should == 'pass1'
  end

  it "doesn't create a user without a password" do
    user1 = Ecore::User.new(@user1_id, :name => 'user1')
    user1.save.should == false
    user1.errors.should == {:password => ["password required"]}
  end

  it "creates a new user" do
    user1 = Ecore::User.new(@user1_id, :name => 'user1', :password => 'pass1')
    user1.save.should == true
  end

  it "creates a new user with create method" do
    user1 = Ecore::User.create(@user1_id, :name => 'user1', :password => 'pass1')
    user1.class.should == Ecore::User
  end

  it "finds an existing user in the database" do
    u1 = Ecore::User.find(@user1_id, :name => 'u1').receive
    u1.class.should == Ecore::User
  end

  it "attaches additional Sequel methods like :order, :limit to the dataset" do
    u1 = Ecore::User.find(@user1_id, :name => 'u1').order(:name.desc).receive
    u1.class.should == Ecore::User
  end

  it "creates a created_at datetime entry after creation" do
    user1 = Ecore::User.create(@user1_id, :name => 'user1', :password => 'pass1')
    user1.created_at.class.should == Time
  end

  it "creates an updated_at datetime entry after creation and update" do
    user1 = Ecore::User.create(@user1_id, :name => 'user1', :password => 'pass1')
    user1.updated_at.class.should == Time
  end

  it "updates a user entry" do
    u1 = Ecore::User.find(@user1_id, :name => 'u1').receive
    u1.name = 'u1.1'
    u1.save.should == true
    u1.reload.name.should == 'u1.1'
    Ecore::User.find(@user1_id, :name => 'u1.1').receive.name.should == 'u1.1'
  end

  it "updates a user entry with update method" do
    u1 = Ecore::User.first(:name => 'u1')
    now = Time.now
    u1.update(:last_request_at => now)
    Ecore::User.first(:name => 'u1').last_request_at.strftime('%d.%m.%y %H:%M').should == now.strftime('%d.%m.%y %H:%M')
  end

  it "sets role to default role specified in ecore.yml" do
    Ecore::User.find(@user1_id, :name => 'u1').receive.role.should == Ecore::env.get(:users)[:default_role]
  end

  it "tells if a user is currently online (according to timeout setting in ecore.yml)" do
    Ecore::User.find(@user1_id, :name => 'u1').receive.online?.should == false
  end

  it "tells if a user has been suspended" do
    Ecore::User.find(@user1_id, :name => 'u1').receive.suspended?.should == false
  end

  it "creates a new group object" do
    group1 = Ecore::Group.create(@user1_id, :name => 'group1')
    group1.class.should == Ecore::Group
  end

  it "finds groups only" do
    group1 = Ecore::Group.create(@user1_id, :name => 'group1')
    Ecore::User.find(@user1_id).receive(:all).size.should == 3
    Ecore::Group.find(@user1_id).receive(:all).size.should == 2
  end

  it "adds group to a user" do
    @u1.groups.size.should == 0
    @u1.add_group(@g1)
    @u1.save.should == true
    @u1.groups.size.should == 1
  end

  it "adds a group to a user and saves automatically" do
    @u1.groups.size.should == 0
    @u1.add_group!(@g1)
    @u1.reload.groups.size.should == 1
  end

  it "lists a users's groups" do
    @u1.groups.size.should == 0
    @u1.add_group!(@g1)
    @u1.groups.first.id.should == @g1.id
  end

  it "removes a group from a user's group list" do
    @u1.add_group!(@g1)
    @u1.groups.size.should == 1
    @u1.remove_group(@g1)
    @u1.save
    @u1.reload.groups.size.should == 0
  end

  it "removes a group from a user's group list and saves user" do
    @u1.add_group!(@g1)
    @u1.groups.size.should == 1
    @u1.remove_group!(@g1)
    @u1.reload.groups.size.should == 0
  end

  it "adds 2 groups to a user" do
    @u1.groups.size.should == 0
    @u1.add_group!(@g1)
    @u1.add_group!(Ecore::Group.create(@user1_id, :name => 'g2'))
    @u1.groups.size.should == 2
  end

  it "adds 2 groups to a user and removes one (one should be left)" do
    @u1.add_group!(@g1)
    @u1.add_group!(Ecore::Group.create(@user1_id, :name => 'g2'))
    @u1.groups.size.should == 2
    @u1.remove_group!(@g1)
    @u1.reload.groups.size.should == 1
  end

  it "lists a group's members (users)" do
    @u1.add_group!(@g1)
    @g1.reload.users.size.should == 1
    @g1.users.first.id.should == @u1.id
  end

  it "returns the anybody user (with id=AAAAAAAA)" do
    Ecore::User.anybody.class.should == Ecore::User
    Ecore::User.anybody.id.should == "AAAAAAAA"
  end

  it "returns a user by providing just an id" do
    Ecore::User.first(@u1.id).class.should == Ecore::User
  end

  it "returns own id and all group ids as a string" do
    @u1.add_group!(@g1)
    @u1.id_and_group_ids.should == "#{@u1.id},#{@g1.id}"
  end

  it "returns fullname or name if no name is set" do
    @u1.fullname_or_name.should == "u1"
    @u1.fullname = "fullname1"
    @u1.fullname_or_name.should == "fullname1"
  end

  it "returns the number of users in the repository" do
    Ecore::User.count.should == 1
  end

  it "returns the number of groups in the repository" do
    Ecore::Group.count.should == 1
  end

end
