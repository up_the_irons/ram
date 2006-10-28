require File.dirname(__FILE__) + '/../test_helper'
require 'article_controller'

# Re-raise errors caught by the controller.
class ArticleController; def rescue_action(e) raise e end; end
class ArticleControllerTest < Test::Unit::TestCase
  #fixtures :users, :articles, :collections, :linkings, :memberships
  fixtures :users, :articles, :tags, :collections, :memberships, :linkings, :taggings
  def setup
    @controller = ArticleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @title   = "Questions for the seller."
    @excerpt = "To whom it may concern"
    @body    = "To whom it may concern, I am writing to enquire about the vintage computer space stand-up, which was used in the movie Solient Green. It is still for sale?"
    login_as :quentin
    @current_user = User.find(@request.session[:user])
    @another_user = users(:ralph_baer)
  end

  
  def test_create_article
    #[true, false].each do |allow_comments|
      post :write, :article=>article_params({:allow_comments=>true})
      assert_redirected_to :action=>'write', :id=>assigns(:article).id
      assert assigns(:article), "Article should be assigned"
      assert_equal assigns(:article).allow_comments?, true, "Allow Comments should be #{true}"
    #end
  end
  
  def test_read
    a = @current_user.articles[0]
    [a.id, a.title].each do |id|
      get :read, :id=>id
      assert_response :success
      assert_equal assigns(:article).title, a.title
    end
  end
  
  def test_read_on_bad_id
    assert_raise(ActiveRecord::RecordNotFound) do
      Article.find(-11)
    end
  end
  
  def test_edit_existing_article
    a = @current_user.articles.find(:first)
    params =  article_params
    #ensure no params match
    params.each_pair{|k,v| assert a[k] != v, ":#{k} should not be equal <#{a[k]}> but was <#{v}>"}
    params.merge!({:category_id=>a.category_id})
    post :write, :id=>a.id, :article=>params
    assert assigns(:article)
    #ensure all params match
    assert_equal assigns(:flash)[:notice], "\"#{assigns(:article).title}\" was saved.<br/>Added (#{assigns(:added).size}) groups and removed (#{assigns(:removed).size})"
    params.each_pair{|k,v| assert_equal assigns(:article)[k], v, ":#{k} should equal <#{assigns(:article)[k]}> but was <#{v}>"}
  end
  
  def test_tags_can_be_added_or_removed
    a = @current_user.articles.find(:first)
    assert a.tags.empty?
    # Add tags
    post :write, :id=>a.id, :article=>{:tags=>"foo,bar,baz,\"ruby on rails\""}
    assert_response :success
    assert_equal 4, assigns(:article).tags.size
    
    # Now remove all tags
    a = @current_user.articles.find(:first)
    post :write, :id=>a.id, :article=>{}
    assert_response :success
    assert_equal 0, assigns(:article).tags.size
  end
  
  def test_write_new_article
    get :write
    assert assigns(:article).new_record?
  end
  
  def test_link_article_to_groups
    post :write, :article=>article_params.merge({:group_ids=>users(:quentin).groups.map{|g|g.id} })
    assert_redirected_to :action=>'write', :id=>assigns(:article).id
    assert_equal assigns(:article).groups.size, users(:quentin).groups.size
  end
  
  def test_delete_article_remove_linkings_to_groups
    login_as :quentin
    post :write, :article=>article_params.merge({:group_ids=>users(:quentin).groups.map{|g|g.id} })
    @a = assigns(:article)
    @groups = assigns(:article).groups
    assert @groups.size > 1
    @groups.each do|g|
      assert Linking.find_by_linkable_type_and_linkable_id_and_group_id('Article',@a.id,g.id)
    end
    post :shred, :id=>@a.id
    assert assigns(:flash)[:notice] = 'Your Article was deleted.'
    assert_raise(ActiveRecord::RecordNotFound) do
      Article.find(@a.id)
    end
    
    @groups.each do|g|
      assert_equal nil, Linking.find_by_linkable_type_and_linkable_id_and_group_id('Article',@a.id,g.id)
    end
    
  end
  
  def test_article_shall_belong_to_only_unique_groups
    post :write, :article=>article_params.merge({:group_ids=>users(:quentin).groups.map{|g|g.id} })
    assert_redirected_to :action=>'write', :id=>assigns(:article).id
    assert_equal assigns(:article).groups.size, users(:quentin).groups.size
    orig_size = assigns(:article).groups.size
    post :write, :id=>assigns(:article).id, :article=>article_params.merge({:group_ids=>users(:quentin).groups.map{|g|g.id} })
    assert_equal assigns(:article).groups.size, orig_size
  end
  
  # This should probably be an integration test.
  def test_users_shall_not_see_article_unless_they_have_access_though_groups
    # Login and get an article of this user
    login_as :user_4

    user = users(:user_4)
    assert_equal false, user.is_admin?
    a = an_article(:user_id=>user.id, :category_id=>user.categories[0].id, :published_at=>Time.now.to_s)
    assert(a.valid?)
    
    # Remove all the groups of this article
    a.remove_all_groups
    assert_equal a.groups(true).size, 0
    
    # Find the groups that have access to the category where this article resides
    category = Category.find(a.category_id)
    category.groups << Group.find_by_name('Mavens and Mavericks')
    assert 3, category.groups(true).size
    category_groups = category.groups
    
    # Assign the members of the first group in the category access to the article
    a.groups << category_groups[0]
    assert_equal a.groups(true).size, 1
    
    # Get all active and remaing users, who don't already belong to one of these groups and are not admins. Then add them to the category's second group
    remaining_users = User.find(:all).map{|u| u unless u.is_admin? || !u.account_active? }.compact
    remaining_users = remaining_users - (category_groups[0].users + category_groups[1].users).flatten.uniq!
    assert_difference category.groups[2].users, :size do
      category.groups[2].users << remaining_users[0]
    end
    
    # Ensure that current_user can read their article
    get :read, :id=>a.id
    assert_equal assigns(:article).title, a.title
    assert_response :success    
    
    # Logout as the current user and login as a new one.
    @controller = AccountController.new
    post :logout
    post :login, :login=> remaining_users[0].login, :password => 'qazwsx'
    
    @controller = ArticleController.new
    assert_equal assigns(:current_user).login, remaining_users[0].login
    # Now try to view the article as the user who has access to the category but not access to the group which controls the article
    get :read, :id=>a.id
    assert_redirected_to :controller=>'inbox'
    assert assigns(:flash)[:notice] = "Could not find article."
  end
  
  def test_prevent_edit_on_get
    a = @current_user.articles.find(:first)
    params =  article_params
    # Ensure no params match
    params.each_pair{|k,v| assert a[k] != v, ":#{k} should not be equal <#{a[k]}> but was <#{v}>"}
    params.merge({:category_id=>a.category_id,:user_id=>a.user_id})
    get :write, :id=>a.id, :article=>params
    assert assigns(:article)
    # Ensure no params match
    params.each_pair{|k,v| assert assigns(:article)[k] != v, ":#{k} should not be equal <#{assigns(:article)[k]}> but was <#{v}>"}
  end
  
  def test_shall_not_edit_articles_without_ownership
    login_as :user_4
    a = users(:quentin).articles[0]
    post :write, :id=>a.id, :article=>{:title=>'don\'t change a thing'}
    assert assigns(:article).new_record?
    assert assigns(:flash)[:notice] = 'Could not find article'
  end
  
  def test_shall_not_view_articles_without_access
    login_as :user_4
    a = users(:quentin).articles[0]
    get :read, :id=>a.id
    assert_redirect :controller=>'inbox'
    assert_equal "Could not find article.", assigns(:flash)[:notice]
  end
  
  def test_delete_article
    @a = an_article({:user_id=>users(:quentin).id})
    post :shred, :id=>@a.id
    assert assigns(:flash)[:notice] = 'Your Article was deleted.'
    assert_raise(ActiveRecord::RecordNotFound) do
      Article.find(@id)
    end
  end
  
  def test_non_published_articles_are_not_viewable_except_to_author_or_admin
    login_as :user_4
    a = an_article({:user_id=>users(:user_4).id})
    a.groups << users(:user_4).groups[0] # Ensure that there is atleast one group in common
    get :read, :id=>a.id
    assert_response :success
    assert_equal assigns(:article).title, a.title
    
    # Now switch the user and assert that the article cannot be seen.
    b = an_article({:user_id=>@another_user.id})
    b.groups << users(:user_4).groups[0] # Ensure that there is atleast one group in common
    assert b.valid?
    get :read, :id=>b.id
    assert_redirected_to :controller=>'inbox'
  end
  
  def test_shall_prevent_on_gets
    @a = users(:quentin).articles[0]
    get :shred, :id=>@a.id
    assert assigns(:flash)[:notice] = 'Could not find article'
    assert Article.find(@a.id)
  end
  
  def test_shall_prevent_deletes_without_acces
    @a = users(:quentin).articles[0]
    login_as :user_4
    post :shred, :id=>@a.id
    assert assigns(:flash)[:notice] = 'Could not find article'
    assert Article.find(@a.id)
  end
  
  def test_add_comment_on_article
    a = an_article({:allow_comments=>true,:user_id=>users(:quentin).id})
    users(:quentin).groups.each{|g| a.groups << g}
    assert a.valid?
    get :read, :id=>a.id
    assert_equal assigns(:article).title, a.title
    post :comment_on, :id=>a.id, :comment=>{:user_id=>users(:quentin).id ,:title=>'this is total bullocks',:body=>'How can you say that "Baby-Pac" was better than "Pac-Man" you are totally wrong you n00b.'}
    assert_redirected_to :controller=>'article',:id=>a.id
    assert assigns(:comment).valid?
    assert_equal 'this is total bullocks', assigns(:comment).title
    assert_equal 1, Article.find(a.id).children_count
  end
  
  def test_shall_prevent_comments_on_articles_that_block_comments
    a = an_article({:allow_comments=>false})
    get :read, :id=>a.id
    assert_equal assigns(:article).title, a.title
    post :comment_on, :id=>a.id, :comment=>{:user_id=>users(:quentin).id ,:title=>'this is total bullocks',:body=>'How can you say that "Baby-Pac" was better than "Pac-Man" you are totally wrong you n00b.'}
    assert_response :success
    assert_equal "Your comments were not saved.", assigns(:flash)[:notice]
    assert_equal 0, Article.find(a.id).children_count
  end
  
  protected
  def article_params(opts={})
    t = "#{Time.now.to_s}"
    params = {:body=>"#{@body}"<<t, :title=>"#{@title}"<<t, :excerpt=>@excerpt, :allow_comments=>true}.merge!(opts)
  end

end
