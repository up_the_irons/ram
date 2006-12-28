module IncludedTests::GroupMethodsTest
  def test_shall_list_groups
     get :groups
     assert :success
     assert assigns(:groups)
  end
   
  def test_admins_will_automatically_get_assigned_to_new_groups
    login_as :administrator
    @user = users(:administrator)
    before = @user.groups.size
    Group.create({ :name => "Group_#{Time.now.to_s}",:user_id=>users(:normal_user).id })
    @user = User.find(@user.id)
    assert_equal before+1, @user.groups.size
  end
   
  def test_shall_show_groups
    login_as :administrator
    get :show_group, :id=>users(:administrator).groups[0].id
    assert assigns(:group)
  end
   
  def test_admin_shall_edit_groups
    login_as :administrator
    get :edit_group, :id=>users(:administrator).groups[0].id
    assert :success
    assert assigns(:group)
  end
  
  def test_update_group
    login_as :administrator

    # User.is_admin? changed from looking at "role" field to seeing if the user is in group named "Administrators", so 
    # if we change the name of this group, we get screwed; therefore, we filter out "Administrators" from this find()
    g = users(:administrator).groups.find(1)
    new_name = 'Atari Monkeys'
    new_tags = ["atari", "2600"]
    assert_not_nil g
    post :edit_group, :id => g.id, :group => {:name => new_name, :tags => new_tags.join(', '), :user_ids => [users(:administrator).id] }
    assert_response :success
    group_after_update = users(:administrator).groups.find(:first, :conditions => "name = '#{new_name}'")
    assert group_after_update
    assert_equal new_name, group_after_update.name
    assert (new_tags - group_after_update.tags.map { |o| o.name }).empty?

    # Make sure tags display correctly (comma delimited)
    assert_tag :tag => 'input', :attributes => { :value => 'atari, 2600' }

    # Now make sure the old tags get overwritten with new ones
    new_tags = ['beach', 'bird','dog']
    post :edit_group, :id => g.id, :group => {:name => new_name, :tags => new_tags.join(', '), :user_ids => [users(:administrator).id] }
    assert_response :success
    group_after_update = Group.find(g.id)
    assert_equal new_name, group_after_update.name
    assert (new_tags - group_after_update.tags.map { |o| o.name }).empty?, "New tags (#{new_tags.join(',')}) expected, but were: #{group_after_update.tags.join(',')}"

    # Make sure tags display correctly (comma delimited)
    assert_tag :tag => 'input', :attributes => { :value => 'beach, bird, dog' }
  end
  
  def test_remove_categories_from_a_group
    login_as :administrator
    admins = Group.find($APPLICATION_SETTINGS.admin_group_id)
    assert admins.categories.size > 1
    # remove half of the categories
    remaining_categories = admins.categories.map{|x|x.id}[0..admins.categories.size/2]
    assert !remaining_categories.empty?
    post :edit_group, :id => admins.id, :group => {:name => admins.name, :user_ids => admins.users.map{|u| u.id}, :tags => admins.tags.join(', '), :category_ids => remaining_categories }
    # Assert that the remaining categories are correct
    assert_equal remaining_categories, assigns(:group).categories.map{|x| x.id}
  end

  def test_update_group_with_blank_tags
    new_tags = ['beach', 'bird','dog']
    g = users(:administrator).groups.find(:first, :conditions => "name != '#{Group.find($APPLICATION_SETTINGS.admin_group_id).name}'")
    post :edit_group, :id => g.id, :group =>{:name=>'Atari Monkeys', :user_ids => [users(:administrator).id], :tags => new_tags.join(', ')}
    assert_response :success
    
    # Make sure tags display correctly (comma delimited)
    assert_tag :tag => 'input', :attributes => { :value => 'beach, bird, dog' }

    # Now let's delete the tags
    post :edit_group, :id => g.id, :group =>{:name=>'Atari Monkeys', :user_ids => [users(:administrator).id], :tags => ''}
    assert_response :success
    assert_tag :tag => 'input', :attributes => { :value => '' }
  end
   
  def test_group_add_member_and_categories_from_multiselect
    login_as :administrator
    c = collections(:collection_3)
    @request.env["HTTP_REFERER"] = "show_group/1"
    event_count_before = Event.count
    add_some_members_to_group(c, 3)
    assert_equal c.users(true).size, 3
    assert_equal event_count_before + 3, Event.count
    
    new_categories = (users(:administrator).categories - c.categories).map{|cat| cat.id}
    assert new_categories.size > 0
    # Remove all but one user, and remove all the categories
    event_count_before = Event.count
    post :edit_group, :id=>c.id, :group=>{:user_ids=>[c.users[0].id],:category_ids=>[]}
    assert_response :success
    assert_equal 1, c.users(true).size
    assert_equal 0, c.categories(true).size
    assert_equal event_count_before + 2, Event.count
    
    users = User.find(:all) - c.members
    # Add new members and new categories
    event_count_before = Event.count
    post :edit_group, :id=>c.id, :group=>{:user_ids=>[c.users[0].id, users[0].id],:category_ids=>new_categories}
    assert_equal c.users(true).size, 2
    assert_equal new_categories.size, c.categories(true).size
    assert_equal event_count_before + 1, Event.count
    assert c.users.find(users[0].id)
    assert_response :success
  end

  def test_disband_group
    login_as :administrator
    users(:administrator).groups.each do |g|
      unless g.name == Group.find($APPLICATION_SETTINGS.admin_group_id).name
        # 1 Event is sent to admin "administrator" and 1 for each user belonging to this group
        assert_difference Event, :count, (1 + g.users.count) do
          post :disband_group, :id=>g.id 
          assert_redirect :groups
          assert_equal "You disbanded the group.", assigns(:flash)[:notice]
        end
      
        get :show_group, :id=>g.id
        assert_redirect :groups
        assert_equal assigns(:flash)[:notice], "Could not find group."
      end
    end
  end
  
  def test_removing_group_updates_category_tree
    u = users(:normal_user)
    login_as :normal_user
    u.categories_as_tree(true) # Reload
    non_admin_group = collections(:collection_40)
    non_admin_category = collections(:collection_41)
    assert non_admin_group.categories.include?(non_admin_category)
    get :index
    # The user doesn't have access to this category
    assert !assigns(:current_user).categories.include?(non_admin_category)
    # Their category tree doesn't display this category
    assert !@controller.session[:category_tree][:b_41]
    
    # Simulate an Admin adding a user to a group, which has access to this category.
    u.groups << non_admin_group
    assert u.groups(true).include?(non_admin_group)
    
    # If they log in again they should have access to this category
    login_as :normal_user
    get :index
    assert @controller.session[:category_tree][:b_41]
    
    # If the group is destroyed they should lose access to this category
    Group.destroy(non_admin_group.id)
    login_as :normal_user
    get :index
    assert !assigns(:current_user).categories.include?(non_admin_category)
    @controller.session[:category_tree] = User.find(u.id).categories_as_tree
    # Their category tree doesn't display this category
    assert !@controller.session[:category_tree][:b_41]
    
  end
  
  def test_remove_admin_from_group
    login_as :administrator
    g = users(:administrator).groups.find(:first, :conditions => "name != '#{Group.find($APPLICATION_SETTINGS.admin_group_id).name}'")
    # Ensure the admin is not the only group memeber.
    assert_difference g.users(true), :size do
      g.users << users(:normal_user)
    end if g.users.size < 1
    group_members = []
    g.users.map{|u| group_members << u.id unless u.id == users(:administrator).id}
    post :edit_group, :id => g.id, :group =>{:user_ids => group_members}
    assert_response :redirect
    assert_equal "You are no longer have access to \"#{g.name}\"", assigns(:flash)[:notice]
    assert !users(:administrator).groups(true).include?(g)
  end
  
  def test_rescue_on_invalid_disband
    login_as :administrator
    post :disband_group, :id=>-1000
    assert_redirect :groups
    assert_equal assigns(:flash)[:notice], "Could not find group."
  end

  def test_prevent_disband_group_on_get
    get :disband_group
    assert_redirected_to :action=>'groups'
  end

  def test_prevent_disband_group_by_unauthorized_users
    login_as :user_without_group_memberships #has no access to any groups 
    assert_no_difference Group, :count do
      @doomed = Group.find(:first).id
      post :disband_group, :id=>@doomed
    end
    assert Group.find(@doomed)
  end
  
  def test_create_group
    login_as :administrator
    assert_no_difference Group, :count do
      post :edit_group, :group => { :name => '', :user_id => users(:administrator).id }
      assert assigns(:group).new_record?
      assert_equal 1, assigns(:group).errors.count
    end

    assert_difference Group, :count  do
      # 1 Event is sent for Group creation and 1 is sent to notify administrator he has been added to the new group
      assert_difference Event, :count, 2 do
        new_tags = ["atari", "2600"]
        post :edit_group, :group => { :category_ids=>users(:administrator).categories.map{|c|c.id}, :name =>'Guest Group', :user_ids=>[users(:administrator).id], :user_id=>users(:administrator).id, :user_ids=>[users(:administrator).id], :tags => new_tags.join(', ')}
        assert_redirected_to :action => 'edit_group'
        assert_equal 0, assigns(:group).errors.count
        assert assigns(:group)

        #assert_equal users(:administrator).categories.size, assigns(:group).categories.size 
        assert (new_tags - assigns(:group).tags.map { |o| o.name }).empty?

        # Make sure tags display correctly (comma delimited)
        get :edit_group, :id => assigns(:group).id
        assert_tag :tag => 'input', :attributes => { :value => 'atari, 2600' }
      end

    end
  end
  
  def test_cannot_create_a_group_without_members
    login_as :administrator
    props = {:name=>"foo", :tags=>"", :user_ids=>[], :description=>"", :user_id=>users(:administrator).id}
    assert_no_difference Group, :count do
      post :edit_group, :group=>props
      assert assigns(:group).new_record?
      assert_equal "The group requires at least one: user_id", assigns(:group).errors[:base]
    end
    props[:user_ids] = [users(:administrator).id]
    assert_difference Group, :count do
      post :edit_group, :group=>props
      assert assigns(:group).valid?
    end
  end
  
  protected
  def add_some_members_to_group(group, num = 1)
    users = User.find(:all) - group.members
    num.times do |u|
      group.members << users[u] unless u >= users.length
    end
  end
end
