require ::File::expand_path( "../spec_helper", __FILE__ )

describe "Document hooks" do

  before(:all) do
    @user1_id = "1"
    Ecore::db.drop_table(:hook_as) if Ecore::db.table_exists?(:hook_as)
    class HookA
      include Ecore::DocumentResource
      attribute :a, :integer
      attribute :c, :integer
      before :create, :increase_a
      after  :create, :increase_a
      before :save, :increase_a
      after  :save, :increase_a
      before :destroy, :increase_a
      after  :destroy, :increase_a
      after :initialize, :increase_b

      private

      def increase_a
        self.a ||= 0
        self.a += 1
      end

      def increase_b
        self.c ||= 0
        self.c += 1
      end

    end
    HookA.migrate
  end

  it "runs a hook only before creation" do
    ha = HookA.new(@user1_id, :name => 'a')
    HookA.hooks[:before][:create].size.should == 1
    HookA.hooks[:before][:create].should == {:increase_a => {}}
    ha.run_hooks(:before,:create)
    ha.a.should == 1
  end

  it "runs a hook after creation" do
    ha = HookA.new(@user1_id, :name => 'a')
    HookA.hooks[:after][:create].size.should == 1
    HookA.hooks[:after][:create].should == {:increase_a => {}}
    ha.run_hooks(:after,:create)
    ha.a.should == 1
  end

  it "runs a hook before save" do
    ha = HookA.new(@user1_id, :name => 'a')
    HookA.hooks[:before][:save].size.should == 1
    HookA.hooks[:before][:save].should == {:increase_a => {}}
    ha.run_hooks(:before,:create)
    ha.a.should == 1
  end

  it "runs a hook after save" do
    ha = HookA.new(@user1_id, :name => 'a')
    HookA.hooks[:after][:save].size.should == 1
    HookA.hooks[:after][:save].should == {:increase_a => {}}
    ha.run_hooks(:after,:create)
    ha.a.should == 1
  end

  it "runs a hook after initialize" do
    ha = HookA.new(@user1_id, :name => 'a')
    HookA.hooks[:after][:initialize].size.should == 1
    HookA.hooks[:after][:initialize].should == {:increase_b => {}}
    ha.c.should == 1
  end

  it "runs a hook after destroy" do
    ha = HookA.new(@user1_id, :name => 'a')
    HookA.hooks[:after][:destroy].size.should == 1 # one inside orig document_resource
    HookA.hooks[:after][:destroy].should == {:increase_a => {}}
    ha.run_hooks(:after,:destroy)
    ha.a.should == 1
  end

  it "runs a hook before destroy" do
    ha = HookA.new(@user1_id, :name => 'a')
    HookA.hooks[:before][:destroy].size.should == 1
    HookA.hooks[:before][:destroy].should == {:increase_a => {}}
    ha.run_hooks(:before,:destroy)
    ha.a.should == 1
  end

  it "runs hooks from super classes (if they are Ecore::Documents)" do
    class HookAChild < HookA
    end
    hac = HookAChild.new(@user1_id, :name => 'ac')
    HookAChild.configured_hooks[:before][:destroy].size.should == 1
    HookAChild.configured_hooks[:before][:destroy].should == {:increase_a => {}}
    hac.run_hooks(:before,:destroy)
    hac.a.should == 1
  end

end
