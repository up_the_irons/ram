module IncludedTests::GroupMethodsTest
  def test_shall_list_groups
     get :groups
     assert :success
     assert assigns(:groups)
   end
   
   def test_shall_show_groups
     login_as :quentin
     get :show_group, :id=>2
     assert assigns(:group)
     assert assigns(:non_members)
     assert_equal assigns(:group).users - assigns(:non_members), assigns(:group).users
   end
   
   def test_admin_shall_edit_groups
     get :edit_group
     assert_redirected_to :action=>'groups'
     get :edit_group, :id=>assigns(:current_user).groups[0].id
     assert :success
   end
  
   def test_update_group
     get :dashboard #needed to get the controller to assign current_user
     g = assigns(:current_user).groups.find(:first)
     new_name = 'Atari Monkeys'
     assert_not_nil g
     post :update_group, :id => g.id, :group =>{:name=>new_name}
     assert_response :redirect
     group_after_update = Group.find(g.id)
     assert_equal new_name, group_after_update.name
   end
   
   def test_prevent_update_group_on_get
     get :update_group
     assert_response :redirect
   end
   
   def test_prevent_create_group_on_get
     get :create_group
     assert_response :redirect
   end
   
   def test_group_add_member
      login_as :quentin

      c = collections(:collection_3)
      pre_count = c.users.size

      xhr :get, :group_add_member, :id => c.id, :user_id => users(:user_5).id
      assert_response :success

      assert_rjs :replace_html, 'group_members'
      assert_rjs :replace_html, 'available_members'

      assert_rjs :visual_effect, :highlight, 'group_members'

      post_count = Collection.find(c.id).users.size

      assert_equal pre_count + 1, post_count
      assert assigns['group']
    end
    
    def test_group_remove_member
      login_as :quentin

      c = collections(:collection_3)
      u = users(:user_5)

      c.users << u
      pre_count = c.users.size

      xhr :get, :group_remove_member, :id => c.id, :user_id => u.id
      assert_response :success

      assert_rjs :replace_html, 'group_members'
      assert_rjs :replace_html, 'available_members'

      post_count = c.users(true).size

      assert_equal pre_count - 1, post_count
      assert assigns['group']
    end

    def test_destroy_group
      User.find(1).groups.each do |g|
        post :destroy_group, :id=>g.id
        assert :success
        assert_raise(ActiveRecord::RecordNotFound) {
          get :show_group, :id => g.id
        }
      end
    end

    def test_prevent_destroy_group_on_get
      get :destroy_group
      assert_response :redirect
    end

    def test_prevent_destroy_group_by_unauthorized_users
      login_as :user_7 #has no access to any groups 
      assert_no_difference Group, :count do
        post :destroy_group, :id=>Group.find(:first).id
      end
    end
    
    def test_create_group
      login_as :quentin
      get :dashboard
      assert_no_difference Group, :count do
        post :create_group, :group => { :name => '',:user_id=>assigns(:current_user).id }
        assert assigns(:group).new_record?
        assert_equal 1, assigns(:group).errors.count
      end

      assert_difference Group, :count  do
        post :create_group, :group => { :name =>'Guest Group',:user_id=>assigns(:current_user).id }
        assert_redirected_to :action => 'groups'
        assert_equal 0, assigns(:group).errors.count
        assert assigns(:group)
      end
    end
end