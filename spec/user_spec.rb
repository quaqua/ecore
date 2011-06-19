require ::File::expand_path( "../spec_helper", __FILE__ )
require 'digest/sha2'

describe "Ecore::User" do

  before(:all) do
    Ecore::User.all.map(&:destroy)
    Ecore::Group.all.map(&:destroy)
  end
  
  it "should create a new User" do
    u = Ecore::User.new(:name => 'alpha', :password => 'pass')
    u.save.should == true
    u = Ecore::User.where(:name => 'alpha', :hashed_password => Digest::SHA512::hexdigest('pass')).all
    u.size.should == 1
    u.first.name.should == 'alpha'
  end

  it "should create a unique id for User" do
    a1 = Ecore::User.create(:name => 'alpha1', :password => 'pass')
    a1.id.class.should == String
    a1.id.size.should == 36
  end
  
  it "should autocreate a confirmation key, if no password is given" do
    u = Ecore::User.new(:name => 'beta')
    u.save.should == true
    u.confirmation_key.size.should == 128
  end
  
  it "should add a user to a group" do
    u = Ecore::User.create!(:name => 'gamma', :password => 'pass')
    g = Ecore::Group.create!(:name => 'gammagroup')
    u.groups.size.should == 0
    u.add_group(g)
    u.save
    u.groups.first.id.should == g.id
    u.groups.size.should == 1
  end
  
  it "should remove a user from a group" do
    u = Ecore::User.find_by_name('gamma')
    g = Ecore::Group.find_by_name('gammagroup')
    u.groups.size.should == 1
    u.remove_group(g)
    u.save
    u.groups.size.should == 0
  end
  
  it "should not add the same group twice" do
    u = Ecore::User.find_by_name('gamma')
    g = Ecore::Group.find_by_name('gammagroup')
    u.groups.size.should == 0
    u.add_group(g)
    u.save
    u.groups.size.should == 1
    u.add_group(g)
    u.save
    u.groups.size.should == 1
  end
 
  it "should add and save a group to the user" do
    u = Ecore::User.create!(:name => 'delta')
    g = Ecore::Group.find_by_name('gammagroup')
    u.groups.size.should == 0
    g.users.size.should == 1
    u.add_group!( g )
    u.groups.size.should == 1
    g.users.size.should == 2
  end

  it "should add a group to the user with << method" do
    u = Ecore::User.create(:name => 'epsilon')
    u << Ecore::Group.find_by_name('gammagroup')
    u.groups.size.should == 1
  end

end
