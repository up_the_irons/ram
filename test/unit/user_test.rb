require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :users, :collections, :memberships, :linkings

  def test_should_associate_groups
    u = User.find(5)
    s = u.groups.size
    u.groups << Collection.find(1)
    assert_equal s+1, u.groups(true).size

    u.groups << Collection.find(1)
    assert_equal s+1, u.groups(true).size

  end
  
  def test_pending_memberships
    u = User.find(4)
    p = u.pending_memberships.size
    Membership.create(:user_id => 2, :collection_id => u.my_groups.first.id, :collection_type => 'Group')
    assert_equal p+1, u.pending_memberships.size

    Membership.create(:user_id => 5, :collection_id => u.my_groups.first.id, :collection_type => 'Group')
    assert_equal p+2, u.pending_memberships.size

    Membership.create(:user_id => 5, :collection_id => u.my_groups.first.id, :collection_type => 'Group')
    assert_equal p+2, u.pending_memberships.size
  end
  
  # def test_should_not_join_own_group
  # end
  
  def test_should_only_count_unique_categories_in_category_list
    #this user has access to all categories and has redundent memberships though several groups 
    u = User.find(1)
    s = 0
    u.groups.map{|g| s += g.categories.size unless g.categories.empty? }
    assert u.categories.size < s, "The user's categories should be less than the sum of the user's group's categories"
  end
  
  def test_user_shall_create_profile_and_person_after_create
    u = User.create({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' })
    assert Profile.find_by_user_id(u.id), 'Should create profile on user create'
    assert Person.find_by_user_id(u.id), 'Should create person on user create'
  end
  
  def test_shall_determine_if_account_is_active
    u = User.find(1)
    assert u.account_active?
    
    u = User.find_by_login('suspended_user')
    assert_equal u.account_active?, false
  end
  
  def test_shall_determine_admin_status
    u = User.find(1)
    assert u.is_admin?
    
    u = User.find_by_login('suspended_user')
    assert_equal u.is_admin?, false
  end

  def test_should_create_user
    assert_difference User, :count do
      assert create_user.valid?
    end
  end

  def test_should_require_login
    assert_no_difference User, :count do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference User, :count do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference User, :count do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference User, :count do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal users(:quentin), User.authenticate('quentin2', 'quentin')
  end

  def test_should_authenticate_user
    assert_equal users(:quentin), User.authenticate('quentin', 'quentin')
  end

  protected
  def create_user(options = {})
    User.create({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
  end
end
