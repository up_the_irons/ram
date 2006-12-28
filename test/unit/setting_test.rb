require File.dirname(__FILE__) + '/../test_helper'

class SettingTest < Test::Unit::TestCase
  fixtures :users, :collections, :settings, :memberships, :settings
  
  def setup
    g = Group.find_by_name('Administrators')
    @settings = {:application_name => 'Awesomeness Professional', :admin_group_id => g.id, :filesize_limit => 1000 * 1024}
  end
  # Replace this with your real tests.
  def test_setting_validations
    empty_obj = {}
    s = Setting.new
    # All attributes were empty, which produces the maximum number of errors
    assert_no_difference Setting, :count do
      s = Setting.create empty_obj
      assert_equal 2, s.errors[:filesize_limit].size
      assert_equal 2, s.errors[:admin_group_id].size
      assert_equal s.errors[:application_name], "can't be blank"
    end
    # Ok to create the file
    assert_difference Setting, :count do
      s = Setting.create @settings
    end
    
    # Set the good file to bad data
    assert_equal false, s.update_attribute(:filesize_limit, -1) # Too Small
    s = Setting.create @settings
    assert_equal false, s.update_attribute(:filesize_limit, 1000000 * 1024) # Too Large
  end
  
  def test_ensure_preferences_not_nil
    s = Setting.find(:first)
    s.update_attribute(:preferences,nil)
    s = Setting.find(s.id) # force reload
    assert !s.preferences.nil?
  end
  
  def test_prevent_assignment_to_invalid_group
    assert_no_difference Setting, :count do
      @settings[:admin_group_id] = 100000000000000000
      s = Setting.create @settings
      assert_equal "This group is invalid", s.errors[:admin_group_id]
    end
  end

  def test_assigned_admin_group_must_have_at_least_one_member
    g = a_group
    assert g.users.empty?
    assert !g.permanent?
    @settings[:admin_group_id] = g.id
    assert_no_difference Setting, :count do
      @s = Setting.create @settings
      assert_equal "The admin group needs to have at least one member", @s.errors[:admin_group_id]
    end
    
    # Add a user.
    g.users << User.find(:first)
    assert !g.users(true).empty?
    assert_difference Setting, :count do
      @s = Setting.create @settings
      g = Group.find(g.id)
      assert g.permanent?
    end
  end
end
