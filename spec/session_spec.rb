require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Ecore::Session" do

  before(:all) do
    Ecore::User.all.map(&:destroy)
    Ecore::Group.all.map(&:destroy)
    Ecore::User.create!(:name => 'alpha', :password => 'pass')
  end
  
  it "aquires a new session object by passing user data" do
    session = Ecore::Session.new(:name => 'alpha', :password => 'pass')
    session.class.should == Ecore::Session
    session.user.class.should == Ecore::User
    session.user.name.should == 'alpha'
  end

  it "raises an Ecore::Authentication error if user could not authenticate" do
    lambda{ Ecore::Session.new(:name => 'bla', :password => 'bla') }.should raise_error(Ecore::AuthenticationError)
  end

end
