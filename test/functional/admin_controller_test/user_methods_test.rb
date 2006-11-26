module IncludedTests::UserMethodsTest
  def test_shall_list_users
     get :users
     assert :success
     assert assigns(:users)
   end
   
   def test_admins_shall_edit_users_profile
     login_as :administrator # Admin
     post :edit_user, :id=>users(:normal_user).id, :user=>{:email=>'foo@bar.com'},:person=>{:first_name=>'foo'}
     assert_equal assigns(:user).first_name, 'foo'
     assert_equal assigns(:user).email, 'foo@bar.com'
   end
   
   def test_admins_shall_add_and_remove_users_from_groups
     login_as :administrator # Admin
      @user = users(:normal_user)
      assert_equal @user.groups.size, 1
      assert_equal @user.groups[0].id, 1
      post :edit_user, :id=>users(:normal_user).id, :user=>{:group_ids=>[1,2,3]}, :profile=>{},:person=>{}     
      assert assigns(:user)
      assert_equal assigns(:flash)[:notice] , "Your changes have been saved."
      user = User.find(assigns(:user).id) # Force a reload
      assert_equal user.groups.size, 3
      assert assigns(:user).groups.find([1,2,3])
   end
   
   def test_admins_shall_see_all_groups
     # TODO: This does not work because the fixture data incorrectly doesn't assign the admin membership to start with.
     # login_as :administrator
     # get :edit, :id=>users(:normal_user).id
     # assert_equal assigns(:current_user).groups, Group.find(:all)
   end
   
   def test_create_avatar
     login_as :administrator # Non-admin
     file = "#{RAILS_ROOT}/test/fixtures/images/rails.png"
     temp_file = uploaded_jpeg(file)
     assert_difference Avatar, :count, 1 do # There is 1 new asset and 3 new thumbnails
       post :edit_user, :id=>users(:normal_user).id, :avatar=>{:uploaded_data=>temp_file}
       assert assigns(:avatar)
       assert_equal assigns(:avatar).user_id, users(:normal_user).id
     end
     assert_response :success
   end
   
   def test_shall_destroy_user
     login_as :administrator
     u = users(:normal_user)
     get :show_user, :id=>u.id
     assert assigns(:user)
     assert_equal User.find_by_login('normal_user'), assigns(:user)
     
     # Do nothing on get requests.
     assert_no_difference User, :count do
       get :destroy_user, :id=>u.id
       assert_redirected_to :action=>'show_user', :id=>u.id
     end     
     
     # Redirect if no id is supplied.
     assert_no_difference User, :count do
       post :destroy_user
       assert_redirected_to :action=>'users'
       assert_equal assigns(:flash)[:notice], 'Could not find user.'
     end
     
     # Destroy the user
     assert_difference User, :count, -1 do
       post :destroy_user, :id=>u.id
       assert_redirected_to :action=>'users'
       assert_equal assigns(:flash)[:notice], "You deleted #{u.login}"
     end
   end
   
   def test_shall_list_destroyed_users
     u = users(:normal_user)
     assert_difference User, :count, -1 do
       assert u.destroy
     end
     get :deleted_users
     assert_response :success
     assert assigns(:users)
     assert assigns(:users).include?(u)
   end
   
   def test_shall_resurrect_destroyed_users
     u = User.find_by_login('deleted_user',:include_deleted=>true)
     login_as :administrator
     new_state = 2
     assert_difference User, :count do
       post :edit_user, :id=>u.id, :user=>{:state=>new_state}
       assert_equal assigns(:user).state, new_state
     end
   end
   
   def test_shall_find_users_by_login_or_by_id
      login_as :administrator
      get :show_user, :id=>'normal_user'
      assert assigns(:user)
      assert_equal User.find_by_login('normal_user') , assigns(:user)

      get :show_user, :id=> assigns(:user).id
      assert assigns(:user)
      assert_equal User.find_by_login('normal_user') , assigns(:user)
    end
    
    def test_admin_shall_change_account_state
      login_as :administrator # Admin
      new_state = 5 # Fake state to ensure it will be unique
      @user = users(:normal_user)
      assert @user.profile
      assert @user.person
      post :edit_user, :id=>users(:normal_user).id, :user=>{:state=>new_state}
      assert_equal assigns(:user).state, new_state
    end
    
end
