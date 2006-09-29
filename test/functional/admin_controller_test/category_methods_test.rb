module IncludedTests::CategoryMethodsTest
  def test_shall_list_categories
      get :categories
      assert :success
      assert assigns(:categories)
  end
  
  def test_admin_shall_edit_categories
    get :edit_category, :id=>@existing_category_id
    assert :success
  end
  
  def test_create_category
    get :edit_category
    assert_response :success
    assert assigns(:category).new_record?
    assert_no_difference Category, :count do
      post :edit_category, :category => { :name => '' }
      assert assigns(:category).errors[:name]
      assert !assigns(:category).valid?
      assert assigns(:category).new_record?
    end
    
    assert_difference Category, :count  do
      new_name = 'knock-offs'
      new_tags = ["atari", "2600"]
      post :edit_category, :category => { :name =>new_name ,:user_id=>users(:quentin).id ,:parent_id=>users(:quentin).categories[0].id, :tags => new_tags.join(', ')}
      assert_redirect :action=>'edit_category', :id=>assigns(:category).id
      assert assigns(:category)
      assert assigns(:category).name = new_name
      assert (new_tags - assigns(:category).tags.map { |o| o.name }).empty?
    end
    
  end
  
  def test_remove_group_from_category
    s = Category.find(6).groups.size
    post :edit_category, :id=>6, :category=>{:group_ids=>Category.find(6).groups[0..(s-2)].map{|g| g.id}}
    assert_equal Category.find(6).groups.size, s-1
    assert assigns(:category)
  end
  
  
  def test_add_group_to_category
     login_as :quentin
     c = Category.find(@existing_category_id)
     g = a_group({:user_id=>users(:quentin).id})
     g.members << users(:quentin)
     assert g.valid?
     s = c.groups.size
     group_ids = c.groups.map{|cat| cat.id }
     group_ids << g.id
     post :edit_category, :id=>c.id, :category=>{:group_ids=>group_ids}
     reloaded_category = Category.find(@existing_category_id)
     assert_equal reloaded_category.groups.size, s+1
     assert reloaded_category.groups.include?(g)
   end

   def test_user_shall_not_add_a_group_to_a_category_that_they_do_not_belong_to
     login_as :quentin
     current_user = users(:quentin)
     all = Category.find(:all)
     excluded = all - current_user.categories
     c = excluded[0]
     s = c.groups.size
     post :edit_category, :id=>c.id, :group_ids=>current_user.groups.map{|g| g.id}
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
        post :destroy_category, :id => 10
        assert assigns(:flash)[:notice], "Error Deleting Category"
      end
  end
  
  def test_update_category
    new_name = 'Atari Promotions'
    new_tags = ["atari", "2600"]
    cat = Category.find(@existing_category_id)
    changes = cat.changes.size
    post :edit_category, :id => @existing_category_id, :category =>{:name=>'Atari Promotions',:description=>'great give-aways from the past',:user_id=>User.find(:first), :tags => new_tags.join(', ')}
    assert_response :success
    category_after_update = Category.find(@existing_category_id)
    assert_equal new_name, category_after_update.name
    assert (new_tags - category_after_update.tags.map { |o| o.name }).empty?

    assert  cat.changes.size+1, assigns(:category).changes.size
    # Now make sure the old tags get overwritten with new ones
    new_tags = ['beach', 'bird','dog']
    post :edit_category, :id => @existing_category_id, :category =>{:name=>'Atari Promotions',:description=>'great give-aways from the past',:user_id=>User.find(:first), :tags => new_tags.join(', ')}
    assert_response :success
    category_after_update = Category.find(@existing_category_id)
    assert_equal new_name, category_after_update.name
    assert (new_tags - category_after_update.tags.map { |o| o.name }).empty?, "New tags (#{new_tags.join(',')}) expected, but were: #{category_after_update.tags.join(',')}"
    
    #assert that the change_sweeper found these changes.
    assert  cat.changes.size+2, assigns(:category).changes.size
    assert  assigns(:category).changes[assigns(:category).changes.size-1].event = "update"
  end
  
  def test_prevent_bad_updates_to_categories
    @category = users(:quentin).categories[0]
    get :edit_category, :id => @category.id, :category =>{:name=>"New Name #{Time.now.to_s}"}
    assert_equal assigns(:category).name, @category.name
    
    get :edit_category, :id => -1111111, :category =>{:name=>"New Name #{Time.now.to_s}"}
    assert_response :redirect
    assert_equal assigns(:flash)[:notice], 'Could not find category.'
  end
  
end
