module IncludedTests::UserMethodsTest
  def test_shall_list_users
     get :users
     assert :success
     assert assigns(:users)
   end
   
   def test_admins_shall_edit_users_profile
     login_as :quentin #admin
     post :edit_user, :id=>users(:user_3).id, :user=>{:email=>'foo@bar.com'},:person=>{:first_name=>'foo'}
     assert_equal assigns(:user).first_name, 'foo'
     assert_equal assigns(:user).email, 'foo@bar.com'
   end
   
   def test_admins_shall_add_and_remove_users_from_groups
     login_as :quentin #admin
      @user = users(:user_2)
      assert_equal @user.groups.size, 1
      assert_equal @user.groups[0].id, 4
      post :edit_user, :id=>users(:user_2).id, :user=>{:group_ids=>[1,2,3]}, :profile=>{},:person=>{}     
      assert assigns(:user)
      assert_equal assigns(:flash)[:notice] , "Your changes have been saved."
      user = User.find(assigns(:user).id) #force a reload
      assert_equal user.groups.size, 3
      assert assigns(:user).groups.find([1,2,3])
   end
   
   def test_admins_shall_see_all_groups
     #TODO this does not work because the fixture data incorrectly doesn't assign the admin membership to start with.
     #login_as :quentin
     #get :edit, :id=>users(:user_3).id
     #assert_equal assigns(:current_user).groups, Group.find(:all)
   end
   
   def test_create_avatar
     login_as :quentin #non admin
     file = "#{RAILS_ROOT}/test/fixtures/images/rails.png"
     temp_file = uploaded_jpeg(file)
     assert_difference Avatar, :count, 1 do # there is 1 new asset and 3 new thumbnails
       post :edit_user, :id=>users(:user_4).id, :avatar=>{:uploaded_data=>temp_file}
       assert assigns(:avatar)
       assert_equal assigns(:avatar).user_id, users(:user_4).id
     end
     assert_response :success
   end
   
   
   def test_shall_find_users_by_login_or_by_id
      login_as :quentin
      get :show_user, :id=>'nolan_bushnell'
      assert assigns(:user)
      assert_equal User.find_by_login('nolan_bushnell') , assigns(:user)

      get :show_user, :id=> assigns(:user).id
      assert assigns(:user)
      assert_equal User.find_by_login('nolan_bushnell') , assigns(:user)
    end
    
    def test_admin_shall_change_account_state
      login_as :quentin #admin
      new_state = 5 #fake state to ensure it will be unique
      @user = users(:user_4)
      assert @user.profile
      assert @user.person

      post :edit_user, :id=>users(:user_4).id, :user=>{:state=>new_state}
      assert_equal assigns(:user).state, new_state
    end
    
end