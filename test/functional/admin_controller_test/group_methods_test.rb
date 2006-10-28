module IncludedTests::GroupMethodsTest
  def test_shall_list_groups
     get :groups
     assert :success
     assert assigns(:groups)
   end
   
   def test_admins_will_automatically_get_assigned_to_new_groups
     login_as :quentin
     @user = users(:quentin)
     before = @user.groups.size
     Group.create({ :name => "Group_#{Time.now.to_s}",:user_id=>users(:user_2).id })
     @user = User.find(@user.id)
     assert_equal before+1, @user.groups.size
   end
   
   def test_shall_show_groups
     login_as :quentin
     get :show_group, :id=>users(:quentin).groups[0].id
     assert assigns(:group)
   end
   
   def test_admin_shall_edit_groups
     login_as :quentin
     get :edit_group, :id=>users(:quentin).groups[0].id
     assert :success
     assert assigns(:group)
   end
  
   def test_update_group
     login_as :quentin

     # User.is_admin? changed from looking at "role" field to seeing if the user is in group named "Administrators", so 
     # if we change the name of this group, we get screwed; therefore, we filter out "Administrators" from this find()
     g = users(:quentin).groups.find(:first, :conditions => "name != '#{ADMIN_GROUP}'")
     new_name = 'Atari Monkeys'
     new_tags = ["atari", "2600"]
     assert_not_nil g
     post :edit_group, :id => g.id, :group => {:name => new_name, :tags => new_tags.join(', ') }
     assert_response :success
     group_after_update = Group.find(g.id)
     assert_equal new_name, group_after_update.name
     assert (new_tags - group_after_update.tags.map { |o| o.name }).empty?

     # Now make sure the old tags get overwritten with new ones
     new_tags = ['beach', 'bird','dog']
     post :edit_group, :id => g.id, :group => {:name => new_name, :tags => new_tags.join(', ') }
     assert_response :success
     group_after_update = Group.find(g.id)
     assert_equal new_name, group_after_update.name
     assert (new_tags - group_after_update.tags.map { |o| o.name }).empty?, "New tags (#{new_tags.join(',')}) expected, but were: #{group_after_update.tags.join(',')}"
   end
   
   def test_group_add_member_and_categories_from_multiselect
     login_as :quentin
     c = collections(:collection_3)
     @request.env["HTTP_REFERER"] = "show_group/1"
     add_some_members_to_group(c, 3)
     assert_equal c.users(true).size, 3
     
     new_categories = (users(:quentin).categories - c.categories).map{|cat| cat.id}
     assert new_categories.size > 0
     #remove all but one user, and remove all the categories
     post :edit_group, :id=>c.id, :group=>{:user_ids=>[c.users[0].id],:category_ids=>[]}
     assert_response :success
     assert_equal 1, c.users(true).size
     assert_equal 0, c.categories(true).size
     
     users = User.find(:all) - c.members
     #add new members and new categories
     post :edit_group, :id=>c.id, :group=>{:user_ids=>[c.users[0].id, users[0].id],:category_ids=>new_categories}
     assert_equal c.users(true).size, 2
     assert_equal new_categories.size, c.categories(true).size
     assert c.users.find(users[0].id)
     assert_response :success
   end

    def test_disband_group
      login_as :quentin
      users(:quentin).groups.each do |g|
        unless g.name == ADMIN_GROUP
          post :disband_group, :id=>g.id 
          assert_redirect :groups
          assert_equal "You disbanded the group.", assigns(:flash)[:notice]
        
          get :show_group, :id=>g.id
          assert_redirect :groups
          assert_equal assigns(:flash)[:notice], "Could not find group."
        end
      end
    end
    
    def test_rescue_on_invalid_disband
      login_as :quentin
      post :disband_group, :id=>-1000
      assert_redirect :groups
      assert_equal assigns(:flash)[:notice], "Could not find group."
    end

    def test_prevent_disband_group_on_get
      get :disband_group
      assert_redirected_to :action=>'groups'
    end

    def test_prevent_disband_group_by_unauthorized_users
      login_as :user_7 #has no access to any groups 
      assert_no_difference Group, :count do
        @doomed = Group.find(:first).id
        post :disband_group, :id=>@doomed
      end
      assert Group.find(@doomed)
    end
    
    def test_create_group
      login_as :quentin
      assert_no_difference Group, :count do
        post :edit_group, :group => { :name => '',:user_id=>users(:quentin).id }
        assert assigns(:group).new_record?
        assert_equal 1, assigns(:group).errors.count
      end

      assert_difference Group, :count  do
        new_tags = ["atari", "2600"]
        post :edit_group, :group => { :name =>'Guest Group',:user_id=>users(:quentin).id, :tags => new_tags.join(', ')}
        assert_redirected_to :action => 'edit_group'
        assert_equal 0, assigns(:group).errors.count
        assert assigns(:group)
        assert (new_tags - assigns(:group).tags.map { |o| o.name }).empty?
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
