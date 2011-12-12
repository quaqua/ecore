require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Custom transactions" do

  before(:all) do
    Ecore::db.drop_table(:custom_trans_as) if Ecore::db.table_exists?(:custom_trans_as)
    Ecore::db.drop_table(:custom_folders) if Ecore::db.table_exists?(:custom_folders)
    @user1_id = "u1"
    class CustomFolder
      include Ecore::DocumentResource
      default_attributes
    end
    class CustomTransA
      include Ecore::DocumentResource
      default_attributes

      transaction :append, :my_custom_transaction

      private

      def my_custom_transaction
        children.create(CustomFolder, :name => 'cf')
      end
    end
    class CustomTransB
      include Ecore::DocumentResource
      default_attributes

      transaction :append, :my_custom_transaction

      private

      # should fail, because no :name was given
      def my_custom_transaction
        children.create!(CustomFolder, :name => nil)
      end
    end
    CustomFolder.migrate
    CustomTransA.migrate
    CustomTransB.migrate
  end

  it "should run the custom transaction" do
    CustomTransA.create(@user1_id, :name => 'cta').children.size.should == 1
  end

  it "should fail and rollback all transactions of the CustomTransB creation" do
    ctb = CustomTransB.new(@user1_id, :name => 'ctb')
    lambda{ ctb.save }.should raise_error(Ecore::SavingFailed)
  end

end
