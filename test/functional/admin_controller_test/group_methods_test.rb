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
     assert_equal before+1,@user.groups.size
   end
   
   def test_shall_show_groups
     login_as :quentin
     get :show_group, :id=>2
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
     g = users(:quentin).groups.find(:first)
     new_name = 'Atari Monkeys'
     assert_not_nil g
     post :edit_group, :id => g.id, :group =>{:name=>new_name}
     assert_response :success
     group_after_update = Group.find(g.id)
     assert_equal new_name, group_after_update.name
   end
   
   def test_group_add_member_from_multiselect
     login_as :quentin
     c = collections(:collection_3)
     @request.env["HTTP_REFERER"] = "show_group/1"
     add_some_members_to_group(c, 3)
     assert_equal c.users(true).size, 3
     
     #remove all but one user
     post :edit_group, :id=>c.id, :group=>{:user_ids=>[c.users[0].id]}
     assert_response :success
     assert_equal c.users(true).size, 1
     
     users = User.find(:all) - c.members
     post :edit_group, :id=>c.id, :group=>{:user_ids=>[c.users[0].id, users[0].id]}
     assert_equal c.users(true).size, 2
     assert c.users.find(users[0].id)
     assert_response :success
   end

    def test_disband_group
      login_as :quentin
      users(:quentin).groups.each do |g|
        post :disband_group, :id=>g.id
        assert_redirect :groups
        assert_equal assigns(:flash)[:notice], "You disbanded the group."
        
        get :show_group, :id=>g.id
        assert_redirect :groups
        assert_equal assigns(:flash)[:notice], "Could not find group."
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

    def test_prevent_destroy_group_by_unauthorized_users
      login_as :user_7 #has no access to any groups 
      assert_no_difference Group, :count do
        post :disband_group, :id=>Group.find(:first).id
      end
    end
    
    def test_create_group
      login_as :quentin
      assert_no_difference Group, :count do
        post :edit_group, :group => { :name => '',:user_id=>users(:quentin).id }
        assert assigns(:group).new_record?
        assert_equal 1, assigns(:group).errors.count
      end

      assert_difference Group, :count  do
        post :edit_group, :group => { :name =>'Guest Group',:user_id=>users(:quentin).id }
        assert_redirected_to :action => 'edit_group'
        assert_equal 0, assigns(:group).errors.count
        assert assigns(:group)
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