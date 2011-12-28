require ::File::expand_path( "../spec_helper", __FILE__ )

class Comment
  include Ecore::ModelResource

  default_attributes

  attribute :name, :string
  attribute :body_text, :text

  validate :presence, :name

end

def create_comment(num)
  arr = []
  (1..num).each do |i|
    arr << Comment.create!(:name => "comment_#{i}")
  end
  arr
end

describe Ecore::ModelResource do

  before(:all) do
    Ecore::db.drop_table(:comments) if Ecore::db.table_exists?(:comments)
    Comment.migrate
    Ecore::db[:users].delete
    @u1 = Ecore::User.create("a1", :name => 'u1', :password => 'p1')
    @u2 = Ecore::User.create("a2", :name => 'u2', :password => 'p2')
  end

  it "returns the Ecore::ModelResource's table name" do
    Comment.table_name.should eq(:"comments")
  end

  it "returns, if Ecore::ModelResource is skipping auditing" do
    Comment.skip_audit?.should eq(false)
  end

  it "migrates the given Ecore::ModelResource and creates table in the database" do
    Comment.migrate.should eq(nil)
  end

  it "builds a new Ecore::ModelResource but does not save it to the repository" do
    c = Comment.new(nil,:name => 'test', :body_text => 'body test')
    c.name.should eq('test')
  end

  it "builds a new Ecore::ModelResource and saves it to the repostiory" do
    c = Comment.new(nil,:name => 'test')
    c.save.should eq(true)
  end

  it "won't build an Ecore::ModelResource if validation fails" do
    c = Comment.new(nil, :name => nil)
    c.save.should eq(false)
  end

  it "won't create an Ecore::ModelResource if validation fails" do
    Comment.create(nil, :name => nil).should eq(nil)
  end

  it "creates a new Ecore::ModelResource and throws an error, if validation does not pass" do
    lambda{ Comment.create!(nil, :name => nil) }.should raise_error(Ecore::SavingFailed)
  end

  it "creates a new Ecore::ModelResource and stores the given user in created_by" do
    c = Comment.create!(@u1.id, :name => 'test')
    c.created_by.should eq(@u1.id)
  end

  it "creates a new Ecore::ModelResource and stores custom attribute body_text" do
    c = Comment.create!(@u1, :name => 'test', :body_text => 'body')
    Comment.find(@u1, :id => c.id).receive.body_text.should eq('body')
  end

  it "creates a new Ecore::ModelResource and stores the given user in created_by if full user object is given" do
    c = Comment.create!(@u1, :name => 'test')
    c.created_by.should eq(@u1.id)
  end

  it "returns the number of Ecore::ModelResources present in the database" do
    Ecore::db[:comments].delete
    Comment.create!(@u1, :name => 'test')
    Comment.count.should eq(1)
  end

  it "returns the number of filtered Ecore::ModelResources" do
    Ecore::db[:comments].delete
    Comment.create!(@u1, :name => 'test')
    Comment.find(@u1,:name.like("%test%")).count.should eq(1)
  end

  it "finds an Ecore::ModelResource in the repository and returns it if present" do
    Comment.create!(@u1, :name => 'c1')
    c1 = Comment.find(@u1,:name => 'c1').receive
    c1.class.should eq(Comment)
    c1.name.should eq('c1')
  end

  it "validates required attributes before saving and throws error, if missing" do
    cnil = Comment.new(@u1, :name => nil)
    cnil.save.should eq(false)
    cnil.errors.should eq({:name => ['required']})
  end

  it "updates given attributes and saves model to the repository" do
    c1 = Comment.create!(@u1, :name => 'c1')
    c1.update(:name => 'other').should eq(true)
    Comment.find(@u1, :name => 'other').receive.id.should eq(c1.id)
  end

  it "validates attributes, if they still meet the given validation" do
    c1 = Comment.create!(@u1, :name => 'c1')
    c1.update(:name => nil).should eq(false)
    c1.errors.should eq({:name => ['required']})
  end

  it "updates the updated_by field if update is called" do
    c1 = Comment.create!(@u1, :name => 'c1')
    c1.updated_by.should eq(@u1.id)
    c1 = Comment.find(@u2, :id => c1.id).receive
    c1.update(:name => 'other')
    Comment.find(@u1, :id => c1.id).receive.updated_by.should eq(@u2.id)
  end

  it "deletes an Ecore::ModelResource" do
    c1 = Comment.create!(@u1, :name => 'c1')
    Comment.find(@u1, :id => c1.id).receive.class.should eq(Comment)
    c1.destroy.should eq(true)
    Comment.find(@u1, :id => c1.id).receive.should eq(nil)
  end

  it "returns, if given model is a new record or is stored in the repository already" do
    c1 = Comment.new(@u1, :name => nil)
    c1.new_record?.should eq(true)
  end

  it "after storing Ecore::ModelResource to the repository, it is no new_record? any longer" do
    c1 = Comment.new(@u1, :name => 'test')
    c1.save.should eq(true)
    c1.new_record?.should eq(false)
  end

end
