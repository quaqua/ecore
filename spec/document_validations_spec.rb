require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Document validations" do

  before(:all) do
    Ecore::db.drop_table(:val_as) if Ecore::db.table_exists?(:val_as)
    Ecore::db.drop_table(:custom_validations) if Ecore::db.table_exists?(:custom_validations)
    Ecore::db.drop_table(:custom_validation2s) if Ecore::db.table_exists?(:custom_validation2s)
    Ecore::db.drop_table(:custom_validation3s) if Ecore::db.table_exists?(:custom_validation3s)
    Ecore::db.drop_table(:custom_validation4s) if Ecore::db.table_exists?(:custom_validation4s)
    Ecore::db.drop_table(:custom_validation5s) if Ecore::db.table_exists?(:custom_validation5s)
    @user1_id = "1"
    class ValA
      include Ecore::DocumentResource
      attribute :myname, :string
      validate :presence, :myname
    end
  end

  it "should validate presence of attribute :enabled" do
    ValA.new(@user1_id).run_validations.should == false
    ValA.new(@user1_id, :myname => "this").run_validations.should == true
    ValA.new(@user1_id, :myname => "").run_validations.should == false
  end

  it "should return false along with an error message, if validation fails" do
    a = ValA.new(@user1_id)
    a.run_validations
    a.errors.should == {:myname => ['required']}
  end

  it "should validate presence of an integer" do
    class ValA
      attribute :myint, :integer
      validate :presence, :myint
    end
    a = ValA.new(@user1_id, :myname => 'test')
    a.run_validations.should == false
    ValA.new(@user1_id, :myname => 'test', :myint => 32).run_validations.should == true
  end
  
  it "should allow custom validation through block" do
    class CustomValidation
      include Ecore::DocumentResource
      attribute :zeta, :integer
      validate do
        unless zeta > 10
          errors[:zeta] = ['must be greater 10']
          false 
        end
      end
    end
    cv = CustomValidation.new(@user1_id, :zeta => 2)
    cv.run_validations
    cv.errors.should == {:zeta => ['must be greater 10']}
  end
 
  it "should allow custom validation through methods" do
    class CustomValidation2
      include Ecore::DocumentResource
      attribute :theta, :float
      validate :test_theta

      private
      
      def test_theta
        unless theta > 10.0
          @errors[:theta] = ['must be greater 10']
          false 
        end
      end
      
    end
    cv2 = CustomValidation2.new(@user1_id, :theta => 2)
    cv2.run_validations
    cv2.errors.should == {:theta => ['must be greater 10']}
  end

  it "requires a name by default" do
    class CustomValidation3
      include Ecore::DocumentResource
    end
    CustomValidation3.migrate
    cv = CustomValidation3.new(@user1_id)
    cv.run_validations.should == false
    cv.errors.should == {:name => ['required']}
    cv = CustomValidation3.new(@user1_id, :name => 'test')
    cv.run_validations.should == true
    cv.errors.should == {}
  end

  it "validates uniqueness of an attribute" do
    class CustomValidation4
      include Ecore::DocumentResource
      attribute :a, :string
      validate :uniqueness, :a
    end
    CustomValidation4.migrate
    CustomValidation4.new(@user1_id, :name => 'a1', :a => 'a').save.should eq(true)
    CustomValidation4.new(@user1_id, :name => 'a2', :a => 'a').save.should eq(false)
  end

  it "validates email_format an attribute" do
    class CustomValidation4
      include Ecore::DocumentResource
      attribute :a, :string
      validate :email_format, :a
    end
    CustomValidation4.migrate
    CustomValidation4.new(@user1_id, :name => 'a1', :a => 'ab@test.com').save.should eq(true)
    CustomValidation4.new(@user1_id, :name => 'a2', :a => 'a').save.should eq(false)
  end

end
  
