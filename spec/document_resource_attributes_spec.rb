require ::File::expand_path( "../spec_helper", __FILE__ )

describe "DocumentResource attributes" do

  before(:all) do
    Ecore::db.drop_table(:document_as) if Ecore::db.table_exists?(:document_as)
    class DocumentA
      include Ecore::DocumentResource
      attribute :name, :string, :default => "default string", :null => false
      attribute :active, :boolean, :default => false
      attribute :nilbool, :boolean
      attribute :num, :integer, :default => 1
      attribute :cost, :float, :default => 0.5
      attribute :due_at, :date
      attribute :booked_at, :datetime
    end
    DocumentA.migrate
    @user1_id = "1"
    @doc_a_attrs = { :name => 'Document A' }
  end

  it "builds a new document resource" do
    a = DocumentA.new(@user1_id, @doc_a_attrs)
    a.name.should == @doc_a_attrs[:name]
  end

  it "converts strings to integer, if integer attribute is set from form" do
    a = DocumentA.new(@user1_id, :num => "1")
    a.num.should == 1
    a.num = 2
    a.num.should == 2
  end

  it "converts strings to float, if float attribute is set in form" do
    a = DocumentA.new(@user1_id, :cost => "3")
    a.cost.should == 3.0
    a.cost = "3.2"
    a.cost.should == 3.2
    a.cost = 5.235
    a.cost.should == 5.235
  end

  it "converts strings to float, if float attribute is set in form" do
    a = DocumentA.new(@user1_id, :cost => "3")
    a.cost.should == 3.0
    a.cost = "21325,5"
    a.cost.should == 21325.5
  end

  it "converts strings to date, if date attribute is set in form" do
    a = DocumentA.new(@user1_id, :due_at => "2011-01-01")
    a.due_at.should == Time.parse("2011-01-01").to_date
  end

  it "converts strings to datetime, if datetime attribute is set in form" do
    a = DocumentA.new(@user1_id, :booked_at => "2011-01-01 10:00")
    a.booked_at.should == Time.parse("2011-01-01 10:00")
  end

  it "converts strings to boolean" do
    a = DocumentA.new(@user1_id, :active => true)
    a.active.should == true
  end

  it "creates a helper method ending with questionmark if boolean" do
    a = DocumentA.new(@user1_id, :active => true)
    a.active?.should == true
  end

  it "keeps @attributes hash with values" do
    a = DocumentA.new(@user1_id, @doc_a_attrs)
    a.attributes[:name].should == @doc_a_attrs[:name] 
  end

  it "keeps @attributes hash also for nil (but defined) values" do
    a = DocumentA.new(@user1_id, @doc_a_attrs)
    a.attributes[:nilbool].should == nil
  end

  it "keeps @attributes hash with default values" do
    a = DocumentA.new(@user1_id, @doc_a_attrs)
    a.attributes[:active].should == false
  end

  it "generates a unique id according to the :documents table" do
    DocumentA.gen_unique_id.is_a?(String).should == true
    DocumentA.gen_unique_id.size.should == 8
  end

end
