module IncludedTests::CategoryMethodsTest
  def test_shall_list_categories
      get :categories
      assert :success
      assert assigns(:categories)
  end
  
  def test_admin_shall_edit_categories
    get :edit_category
    assert_redirected_to :action=>'categories'
    get :edit_category, :id=>@existing_category_id
    assert :success
  end
  
  def test_create_category
    get :create_category
    assert_response :redirect
    assert_no_difference Category, :count do
      post :create_category, :category => { :name => '' }
      assert assigns(:category).new_record?
    end
    
    assert_difference Category, :count  do
      post :create_category, :category => { :name =>'knock-offs',:user_id=>User.find(:first),:parent_id=>@existing_category_id }
      assert_redirected_to :action => 'categories'
      assert assigns(:category)
    end
  end
  
  def test_remove_group_from_category
    s = Category.find(6).groups.size
    post :remove_group_from_category, :id=>6, :group_id=>1
    assert_equal Category.find(6).groups.size, s-1
    assert assigns(:category)
  end
  
  def test_removing_group_from_category_removes_assets_linked_only_to_that_group
    
  end
  
  def test_add_group_to_category
     c = Category.find(@existing_category_id)
     s = c.groups.size
     post :add_group_to_category, :id=>c.id, :group_id=> 1, :update=>'new_group_form'
     assert flash[:notice] == 'Your Group has been added'
     assert_equal Category.find(@existing_category_id).groups.size, s+1   
   end

   def test_user_shall_not_add_a_group_to_a_category_that_they_do_not_belong_to
     get :dashboard
     current_user = assigns(:current_user)
     all = Category.find(:all)
     excluded = all - current_user.categories
     c = excluded[0]
     s = c.groups.size
     post :add_group_to_category, :id=>c.id, :group_id=> 1, :update=>'new_group_form'
     assert_equal Category.find(c.id).groups.size, s
   end
  
  
  def test_destroy_category_with_and_without_children
      #no children to destroy
      assert_difference Category, :count, -1 do
        post :destroy_category, :id => 15
        assert_redirected_to :action => 'categories'
      end
      #three children to destroy
      assert_difference Category, :count, -4 do
        post :destroy_category, :id => 10
        assert_redirected_to :action => 'categories'
      end
      #already deleted
      assert_no_difference Category, :count do
        assert_raise(ActiveRecord::RecordNotFound) {
          post :destroy_category, :id => 10
        }
      end
  end
  
  def test_update_category
    new_name = 'Atari Promotions'
    post :update_category, :id => @existing_category_id, :category =>{:name=>'Atari Promotions',:description=>'great give-aways from the past',:user_id=>User.find(:first)}
    assert_response :redirect
    category_after_update = Category.find(@existing_category_id)
    assert_equal new_name, category_after_update.name
  end
  
end