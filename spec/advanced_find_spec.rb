require ::File::expand_path( "../spec_helper", __FILE__ )

def create_contact
  @c1 = Contact.create!(@u1.id, :name => 'c1')
  @c1.share!(@g1)
  @c2 = Contact.create!(@u1.id, :name => 'c2')
  @c2.share!(Ecore::User.anybody)
  @c3 = Contact.create!(@u1.id, :name => 'c3')
  @c1.children.push!(@c3)
end

describe "Document Advanced finders" do

  before(:all) do
    Ecore::db[:users].delete
    @u1 = Ecore::User.create("1a",:name => 'u1', :password => 'p1')
    @u2 = Ecore::User.create("1A",:name => 'u2', :password => 'p2')
    @g1 = Ecore::Group.create("1a",:name => 'g1')
    @u1.add_group!(@g1)
    @u2.add_group!(@g1)
    init_users_and_contact_class
  end

  before(:each) do
    Ecore::db[:contacts].delete
    Ecore::db[:labels].delete
    Ecore::db[:documents].delete
    create_contact
  end

  it "finds a contact by passing all group ids, the user is member of" do
    @u1.id_and_group_ids.include?(',').should == true
    Contact.find(@u1.id_and_group_ids).filter(:id => @c1.id).receive.name.should == 'c1'
  end

  it "provides access to other user by find method" do
    Contact.find(@u2.id).filter(:id => @c1.id).receive.should == nil
    Contact.find(@u2.id_and_group_ids).filter(:id => @c1.id).receive.name.should == 'c1'
  end

  it "can read contacts shared with anybody" do
    Contact.find(@u2.id_and_group_ids).filter(:id => @c2.id).receive.name.should == 'c2'
  end

  it "does not modify privileges after changing a document" do
    c1 = Contact.find(@u2.id_and_group_ids).filter(:id => @c1.id).receive
    c1.acl_read.should == "#{@u1.id},#{@g1.id}"
    c1.update(:position => 2).should == true
    c1.acl_read.should == "#{@u1.id},#{@g1.id}"
    c1.acl_write.should == "#{@u1.id},#{@g1.id}"
    c1.acl_delete.should == "#{@u1.id}"
  end

  it "does not modify privileges if changing child content" do
    @c3.parent.id.should == @c1.id
    c3 = Contact.find(@u2.id_and_group_ids).filter(:id => @c3.id).receive
    c3.position = 3
    c3.parent_id = c3.parent_id
    c3.save.should == true
    c3.acl_read.should == "#{@u1.id},#{@g1.id}"
  end

  it "saves a new document to the given document (by parent_id)" do
    c4 = Contact.create!(@u2, :name => 'c4', :parent_id => @c3.id)
    c4.parent.id.should == @c3.id
  end

  it "finds a document by providing a user object" do
    c5 = Contact.create!(@u2, :name => 'c5')
    Contact.find(@u2).filter(:name => 'c5').receive.id.should == c5.id
  end

end
