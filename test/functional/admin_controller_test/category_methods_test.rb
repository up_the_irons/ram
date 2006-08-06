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