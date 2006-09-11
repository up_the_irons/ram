require File.dirname(__FILE__) + '/../test_helper'
require 'article_controller'

# Re-raise errors caught by the controller.
class ArticleController; def rescue_action(e) raise e end; end
class ArticleControllerTest < Test::Unit::TestCase
  #fixtures :articles, :collections, :users, :linkings, :memberships
  fixtures :users, :articles
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
      assert_response :success
      assert assigns(:article), "Article should be assigned"
      assert_equal assigns(:article).allow_comments?, true, "Allow Comments should be #{true}"
    #end
  end
  
  def test_read
    a = Article.find(:first)
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
    params.merge({:category_id=>a.category_id,:user_id=>a.user_id})
    post :write, :id=>a.id, :article=>params
    assert assigns(:article)
    #ensure all params match
    assert_equal assigns(:flash)[:notice], "\"#{assigns(:article).title}\" was saved."
    params.each_pair{|k,v| assert_equal assigns(:article)[k], v, ":#{k} should equal <#{assigns(:article)[k]}> but was <#{v}>"}
  end
  
  def test_write_new_article
    get :write
    assert assigns(:article)
  end
  
  def test_prevent_edit_on_get
    a = @current_user.articles.find(:first)
    params =  article_params
    #ensure no params match
    params.each_pair{|k,v| assert a[k] != v, ":#{k} should not be equal <#{a[k]}> but was <#{v}>"}
    params.merge({:category_id=>a.category_id,:user_id=>a.user_id})
    get :write, :id=>a.id, :article=>params
    assert assigns(:article)
    #ensure no params match
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
    assert_raise(ActiveRecord::RecordNotFound) do
      get :read, :id=>a.id
    end
  end
  
  def test_delete_article
    @a = an_article({:user_id=>users(:quentin).id})
    post :shred, :id=>@a.id
    assert assigns(:flash)[:notice] = 'Your Article was deleted.'
    assert_raise(ActiveRecord::RecordNotFound) do
      Article.find(@id)
    end
  end
  
  def test_non_published_articles_are_not_viewable_except_to_author
    a = an_article({:user_id=>@current_user.id})
    get :read, :id=>a.id
    assert_response :success
    assert_equal assigns(:article).title, a.title
    
    #now switch the user and assert that the article cannot be seen.
    assert_raise(ActiveRecord::RecordNotFound) do
      b = an_article({:user_id=>@another_user.id})
      assert b.valid?
      get :read, :id=>b.id
      assert_response :success
    end
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
    a = an_article({:allow_comments=>true})
    get :read, :id=>a.id
    assert_equal assigns(:article).title, a.title
    post :comment_on, :id=>a.id, :comment=>{:user_id=>users(:quentin).id ,:title=>'this is total bullocks',:body=>'How can you say that "Baby-Pac" was better than "Pac-Man" you are totally wrong you n00b.'}
    assert_response :success
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
    params = {:body=>"#{@body}"<<t, :title=>"#{@title}"<<t, :excerpt=>@excerpt, :user_id=>2, :allow_comments=>true}.merge(opts)
  end

end
