require ::File::expand_path( "../spec_helper", __FILE__ )
require 'digest/sha2'

describe "Ecore::Group" do

  before(:all) do
    Ecore::User.all.map(&:destroy)
    Ecore::Group.all.map(&:destroy)
  end
 
  it "should init and save a new group" do
    g = Ecore::Group.new(:name => 'testgroup')
    g.save.should == true
    Ecore::Group.where(:name => 'testgroup').first.name.should == 'testgroup'
  end

  it "should create a new group" do
    Ecore::Group.create(:name => 'testgroup2').class.should == Ecore::Group
    Ecore::Group.where(:name => 'testgroup2').first.name.should == 'testgroup2'
  end

  it "should create unique ids for a new group" do
    g3 = Ecore::Group.create(:name => 'testgroup3')
    g3.id.class.should == String
    g3.id.size.should == 36
  end

  it "should add a user to a group" do
    u = Ecore::User.create(:name => 'alpha')
    g = Ecore::Group.create(:name => 'alphagroup')
    g.users.size.should == 0
    g << u
    g.users.size.should == 1
  end

  it "should remove a user from the group" do
    u = Ecore::User.find_by_name('alpha')
    g = Ecore::Group.find_by_name('alphagroup')
    g.users.size.should == 1
    g.remove_user!( u )
    g.users.size.should == 0
    u.groups.size.should == 0
  end

  it "should remove a group reference from a user if group is deleted" do
    u = Ecore::User.find_by_name('alpha')
    g = Ecore::Group.find_by_name('alphagroup')
    g << u
    u.groups.size.should == 1
    g.destroy
    Ecore::User.find_by_name('alpha').groups.size.should == 0
  end

end
