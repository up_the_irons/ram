module IncludedTests::UserMethodsTest
  def test_shall_list_users
     get :users
     assert :success
     assert assigns(:users)
   end
   
   def test_admin_shall_edit_users
     todo "Allow admins to edit users."
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
    
end