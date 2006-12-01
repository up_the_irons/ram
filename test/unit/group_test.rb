require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_unit_helper'

class GroupTest < Test::Unit::TestCase
  fixtures :collections, :memberships, :users, :linkings

  def setup
    @model = Group
    @record_one = Group.find(1)
    @new_obj = {
      :name => 'atari fans',
      :description => 'a collection of the most rad game fans eva',
      :state_id => 1,
      :public => true,
      :user_id => 1
    }
  end
  
  def test_create_group
    unit_create @model,@new_obj 
  end
  
  def test_group_shall_accept_new_members
    g= Group.find(2)
    s = g.users.size
    g.users << User.find(4)
    assert g.save
    assert_equal s+1, Group.find(g.id).users.size
  end
  
  def test_cannot_destroy_a_permanent_group
    g = Group.find_by_name(Group.find($APPLICATION_SETTINGS.admin_group_id).name) # Permanent group
    assert_no_difference Group, :count do
      assert_raise(RuntimeError) {g.destroy}
    end

    # Now change the permanent flag to false and delete it
    g.permanent = false
    assert g.save
    g.reload
    assert_difference Group, :count, -1 do
      g.destroy
    end
  end
  
  def test_cannot_rename_a_permanent_group
    g = Group.find($APPLICATION_SETTINGS.admin_group_id) # Permanent group
    assert_unchanged g, :name do
      g.update_attributes({:name=>"#{Time.now.to_s}"})
      assert !g.valid?
      assert g.errors.on("name"), "A perminant Group's name cannot be changed."
    end
  end
  
  def test_group_shall_remove_members
    g = Group.find(:first)
    s = g.memberships.size
    g.remove_member(g.members[0])
    assert g.save
    assert_equal s-1, Group.find(g.id).members.size
  end
  
  def test_group_shall_not_add_the_same_category_twice
    g = Group.find(:first)
    s = g.categories.size
    g.categories << g.categories[0]
    assert g.save
    assert_equal s, Group.find(g.id).categories.size
  end
  
  def test_remove_a_category
    g = Group.find(:first)
    assert g.categories.size > 0
    assert_difference g.categories, :count, -1 do
      g.remove_category(g.categories[0])
    end
  end
  
  def test_remove_all_categories
    g = Group.find(:first)
    assert g.categories.size > 0
    g.remove_all_categories
    assert_equal 0, g.categories(true).size
  end

  def test_remove_all_members
    g = Group.find(:first)
    s = g.memberships.size
    g.remove_all_members
    assert g.save
    members = Group.find(g.id).members
    assert s > members.size
    assert_equal 0, members.size
  end
  
  def test_shall_not_add_duplicate_members
    assert !@record_one.users.include?(User.find(8)), "Fixtures have been modified!"
    s = User.find(8).groups.size
    @record_one.users << User.find(8)
    @record_one.reload
    
    assert @record_one.users.include?(User.find(8))
    assert_not_nil Membership.find(:all, :conditions => 'user_id = 3 and collection_id = 1')
    assert_not_equal [], User.find(8).groups
    assert User.find(8).groups.include?(@record_one)
    assert_equal s+1, User.find(8).groups.size

    @record_one.users << User.find(8)
    assert_equal s+1, User.find(8).groups.size
  end
  
  def test_destroy_group
    unit_destroy @model, collections(:collection_4).id
  end
  
  def test_update_group
    @id = collections(:collection_4).id
    @new_values = {
      :name=> 'Donkey Kong Fans',
      :description=>'A group for those of us that like monkeys and hate plumbers'
    }
    unit_update @model, @id, @new_values
  end
  
  def test_make_group_private
    @id = collections(:collection_4).id
    @group = @model.find(@id)
    @group.public = false
    @group.save
    assert_equal false,  @model.find(@id).public
  end
  
  def test_make_group_public
    @id = collections(:collection_4).id
    @group = @model.find(@id)
    @group.public = true
    @group.save
    assert_equal true,  @model.find(@id).public
  end
  
  def test_switch_owner
    m = Group.find(1).memberships.size
    u = Group.find(1).user
    assert !Group.find(1).memberships.include?(u)
    Group.find(1).switch_ownership(4)
    assert Group.find(1).memberships.map(&:user_id).include?(1)
    assert !Group.find(1).memberships.include?(User.find(4))
  end
end
