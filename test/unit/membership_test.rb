require File.dirname(__FILE__) + '/../test_helper'

class MembershipTest < Test::Unit::TestCase
  fixtures :memberships, :users, :collections

  def test_new_membership_shows_users
    s = User.find(5).memberships.size
    gs = User.find(5).groups.size
    g = Group.find(3).users.size

    m = Membership.create(:user_id => 5, :collection_id => 3, :collection_type => 'Group')
    assert m.save
    assert_equal s+1,  User.find(5).memberships.size
    assert_equal gs+1, User.find(5).groups.size
    assert_equal g+1,  Group.find(3).users.size
  end
  
  def test_default_state
    m = Membership.create(:user_id => 4, :collection_id => 1, :collection_type => 'Group')
    assert_equal 0, m.state_id
    assert_equal 'Pending', m.state
  end
  
  def test_group_owner_cant_be_member
    s = Group.find(1).users.size
    m = Membership.create(:user_id => 4, :collection_id => 1, :collection_type => 'Group')
    assert_equal s, Group.find(1).users.size
    assert !m.valid?
  end
  
  def test_membership_group
    m = Membership.find(1)
    assert_nothing_raised { m.group = Group.find(1) }
  end
  
end
