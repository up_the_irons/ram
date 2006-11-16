require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper

  fixtures :users, :tags, :collections, :memberships, :linkings, :event_subscriptions, :attachments, :taggings

  def test_should_associate_groups
    u = User.find(4)
    s = u.groups.size
    u.groups << Collection.find(2)
    assert_equal s+1, u.groups(true).size

    u.groups << Collection.find(1)
    assert_equal s+1, u.groups(true).size
  end
  
  def test_pending_memberships
    u = User.find(4)
    p = u.pending_memberships.size
    Membership.create(:user_id => 1, :collection_id => u.my_groups.first.id, :collection_type => 'Group')
    assert_equal p+1, u.pending_memberships.size

    Membership.create(:user_id => 4, :collection_id => u.my_groups.first.id, :collection_type => 'Group')
    assert_equal p+2, u.pending_memberships.size

    Membership.create(:user_id => 4, :collection_id => u.my_groups.first.id, :collection_type => 'Group')
    assert_equal p+2, u.pending_memberships.size
  end
  
  # def test_should_not_join_own_group
  # end
  
  def test_should_only_count_unique_categories_in_category_list
    # This user has access to all categories and has redundent memberships though several groups 
    u = User.find(1)
    s = 0
    u.groups.map{|g| s += g.categories.size unless g.categories.empty? }
    assert u.categories.size < s, "The user's categories should be less than the sum of the user's group's categories"
  end
  
  def test_user_shall_create_profile_and_person_after_create
    u = User.create({ :login => 'quire', :email => 'quire@example.com', :password => 'qazwsx', :password_confirmation => 'qazwsx' })
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
  
  def test_adding_a_user_to_the_admin_group_makes_them_an_admin
    u = User.find(4)
    assert_equal false, u.is_admin?
    u.groups << Group.find_by_name(ADMIN_GROUP)
    u.reload
    assert_equal true, u.is_admin?
  end

  def test_should_create_user
    assert_difference User, :count do
      assert create_user.valid?
    end
  end
  
  def test_can_edit_method
    admin = users(:administrator)
    user  = users(:normal_user) 
    user.assets << an_asset({:user_id=>user.id})
    # Admins can edit anything
    assert admin.can_edit?(user.assets[0])
    assert admin.can_edit?(user.groups[0])
    assert admin.can_edit?(user.categories[0])
    
    # Users can edit only the items they create not the items they belong to.
    assert_equal false, user.can_edit?(user.groups[0])
    assert_equal false, user.can_edit?(user.categories[0])
    assert_equal false, user.can_edit?(admin.assets[0])
    assert user.can_edit?(user.assets[0])
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
  
  def test_categories_as_tree
    user = users(:administrator)
    tree = user.categories_as_tree
    user.categories.each do |c|
      sym = "b_#{c.id}".to_sym
      branch = {:children=> [], :id=>c.id,:name=> c.name,:parent=> (c.parent_id == nil)? :root : "b_#{c.parent_id}".to_sym} 
      c.children.each{|child| branch[:children] << tree["b_#{child.id}".to_sym] if user.categories.find{|cat| cat.id == child.id}  }
      assert_equal branch[:id]       , tree[sym][:id]
      assert_equal branch[:parent]   , tree[sym][:parent]
      assert_equal branch[:name]     , tree[sym][:name]
      assert_equal branch[:children].map{|n| n[:name]  }.sort , tree[sym][:children].map{|n| n[:name]  }.sort
    end
  end
  
  def test_shall_encrypt_login
    u = User.find(:first)
    login = u.login
    encrypted = u.encrypt_login 
    assert encrypted != login
    assert_equal User.decrypt_string(encrypted), login
  end

  def test_should_require_email
    assert_no_difference User, :count do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    users(:administrator).update_attributes(:password => 'foobarbaz', :password_confirmation => 'foobarbaz')
    assert_equal users(:administrator), User.authenticate('administrator', 'foobarbaz')
  end

  def test_should_not_rehash_password
    users(:administrator).update_attributes(:login => 'administrator2')
    assert_equal users(:administrator), User.authenticate('administrator2', 'qazwsx')
  end

  def test_should_authenticate_user
    assert_equal users(:administrator), User.authenticate('administrator', 'qazwsx')
  end

  # An Event should be recored after a user is created
  def test_after_create
    # Two users are subscribed to the UserSignup event, so we should get two more Events created
    assert_difference Event, :count, 2 do
      create_user(:login => 'garry')
    end
  end

  def test_event_subscriptions
    es = users(:administrator).event_subscriptions

    e1 = event_subscriptions(:administrator_1)
    e2 = event_subscriptions(:administrator_2)

    assert es.include?(e1)
    assert es.include?(e2)

    assert_equal 4, es.size
  end

  def test_assets_search
    u = users(:normal_user)
    assets = u.assets_search('nes')
    assert_equal 0, assets.size

    assets = u.assets_search('atari')
    assert_equal 3, assets.size

    res = assets.map { |o| o.name }
    assert res.include?('atari2600_console01.jpg')
    assert res.include?('atari-xe-large.jpg')
    assert res.include?('atari-games-stacked.jpg')
  end

  def test_categories_search
    u = users(:administrator)

    cats = u.categories_search('nintendo')
    assert_equal 2, cats.size
    res = cats.map { |o| o.name }
    assert res.include?(collections(:collection_10).name)
    assert res.include?(collections(:collection_30).name)

    cats = u.categories_search('purple')
    assert_equal 2, cats.size
    res = cats.map { |o| o.name }
    assert res.include?(collections(:collection_9).name)
    assert res.include?(collections(:collection_7).name)

    cats = u.categories_search('quarter')
    assert_equal 1, cats.size
    assert_equal collections(:collection_8).name, cats[0].name

    u = users(:normal_user)

    cats = u.categories_search('')
    assert_equal 3, cats.size

    cats = u.categories_search('game')
    assert_equal 2, cats.size
    res = cats.map { |o| o.name }
    assert res.include?('Video Game Database')
    assert res.include?('Games')

    cats = u.categories_search('secret')
    assert_equal 1, cats.size
    assert_equal collections(:collection_9).name, cats[0].name
  end

  def test_groups_search
    u = users(:normal_user)

    p = Proc.new do |names, groups|
      names = [names].flatten
      assert_equal names.size, groups.size

      names.each do |n|
        assert groups.map { |o| o.name }.include?(n)
      end
    end

    groups = u.groups_search('only')
    p.call('Atari', groups)

    groups = u.groups_search('atari')
    p.call('Atari', groups)

    u = users(:administrator)
    groups = u.groups_search('a')
    p.call(['Atari', ADMIN_GROUP], groups)

    groups = u.groups_search('secret')
    p.call(ADMIN_GROUP, groups)

    groups = u.groups_search('purple')
    p.call([ADMIN_GROUP, 'Atari'], groups)
  end

end
