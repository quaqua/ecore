require ::File::expand_path( "../spec_helper", __FILE__ )

describe "DocumentResource definitions" do

  before(:all) do
    @user1_id = "1"
    Ecore::db.drop_table(:document_def_as) if Ecore::db.table_exists?(:document_def_as)
    Ecore::db.drop_table(:document_def_a0s) if Ecore::db.table_exists?(:document_def_a0s)
    Ecore::db.drop_table(:document_def_bs) if Ecore::db.table_exists?(:document_def_bs)
    Ecore::db.drop_table(:document_def_cs) if Ecore::db.table_exists?(:document_def_cs)
  end

  it "creates automatically a general documents table" do
    Ecore::db.table_exists?(:documents).should == true
  end

  it "defines a new document resource with no attributes" do
    class DocumentDefA
      include Ecore::DocumentResource
    end
  end

  it "invokes the migrate method and creates the database tables" do
    Ecore::db.table_exists?(:document_def_as).should == false
    DocumentDefA.migrate
    Ecore::db.table_exists?(:document_def_as).should == true
    Ecore::db[:document_def_as].columns.size.should == 16
  end

=begin # caused to many problems for debugging, cause rspec errors became unreadable
  it "raises an error, if migrate has not been called before instance creation" do
    class DocumentDefA0
      include Ecore::DocumentResource
    end
    lambda{ DocumentDefA0.new(@user1_id).save }.should raise_error(StandardError, 'table does not exist yet in the database (run DocumentDefA0.migrate)')
    lambda{ DocumentDefA0.new(@user1_id, :name => 'test').save }.should raise_error(StandardError, 'table does not exist yet in the database (run DocumentDefA0.migrate)')
  end
=end

  it "defines a new document resource with one attribute as String" do
    class DocumentDefB
      include Ecore::DocumentResource
      attribute :myname, String
    end
    DocumentDefB.migrate
    Ecore::db[:document_def_bs].columns.size.should == 17
  end

  it "adds a new column to DocumentDefB by just changing the class definition and runnging DocumentDefB.migrate" do
    class DocumentDefB
      include Ecore::DocumentResource
      attribute :myname, String
      attribute :other, Integer
    end
    DocumentDefB.migrate
    Ecore::db[:document_def_bs].columns.size.should == 18
  end

  it "default creates :name attribute" do
    class DocumentDefC
      include Ecore::DocumentResource
    end
    DocumentDefC.migrate
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:name).should == true
  end

  it "default creates :id attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:id).should == true
  end

  it "default creates :name attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:name).should == true
    c.attributes.has_key?(:name).should == true
  end

  it "default creates :created_at attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:created_at).should == true
    c.attributes.has_key?(:created_at).should == true
  end

  it "default creates :created_by attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:created_by).should == true
    c.attributes.has_key?(:created_by).should == true
  end

  it "default creates :updated_at attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:updated_at).should == true
    c.attributes.has_key?(:updated_at).should == true
  end

  it "default creates :updated_by attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:updated_by).should == true
    c.attributes.has_key?(:updated_by).should == true
  end

  it "default creates :can_read? attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:can_read?).should == true
  end

  it "default creates :can_write? attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:can_write?).should == true
  end

  it "default creates :can_delete? attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:can_delete?).should == true
  end

  it "default creates :path attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:path).should == true
  end

  it "default creates :label_ids attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:label_ids).should == true
  end

  it "default creates :starred attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:starred).should == true
    c.respond_to?(:starred?).should == true
    c.attributes.has_key?(:starred).should == true
  end

  it "default creates :position attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:position).should == true
    c.attributes.has_key?(:position).should == true
  end

  it "default creates :color attribute" do
    c = DocumentDefC.new(@user1_id)
    c.respond_to?(:color).should == true
    c.attributes.has_key?(:color).should == true
  end

  it "subclasses a documentdef class" do
    class DocumentDefAChild < DocumentDefA
    end
    DocumentDefAChild.table_name.should == :document_def_as
  end

  it "returns a list of classes that include Ecore::DocumentResource" do
    Ecore::DocumentResource.classes.include?("Ecore::Link").should == true
    Ecore::DocumentResource.classes.include?("Contact").should == true
    Ecore::DocumentResource.classes.include?("DocumentDefA").should == true
    Ecore::DocumentResource.classes.include?("DocumentDefB").should == true
    Ecore::DocumentResource.classes.include?("DocumentDefC").should == true
  end

end
