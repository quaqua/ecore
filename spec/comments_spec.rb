require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Comment" do

  before(:all) do
    Comment.all.map(&:delete)
    Ecore::User.all.map(&:destroy)
    @alpha = Ecore::User.create!(:name => 'alpha', :password => 'alpha')
    @session = Ecore::Session.new(:name => 'alpha', :password => 'alpha')
    @f = Folder.create!(:session => @session, :name => 'commenttest')
  end

  it "should create a comment for an existing node" do
    comment = @f.comments.create(:body_text => "This is my comment", :user_id => @alpha.id)
    comment.node_type.should == 'Folder'
    comment.node_id.should == @f.id
    comment.user_id.should == @alpha.id
  end

  it "should return the comment's node" do
    comment = @f.comments.first
    comment.session = @session
    comment.node.id.should == @f.id
  end

  it "should return the comment's user" do
    comment = @alpha.comments.first
    comment.session = @session
    comment.user.id.should == @alpha.id
  end

end
