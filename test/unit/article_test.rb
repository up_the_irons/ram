#  id                  :integer(11)   not null
#  parent_id           :integer(11)   
#  user_id             :integer(11)   
#  title               :string(255)   
#  permalink           :string(255)   
#  excerpt             :text          
#  body                :text          
#  excerpt_html        :text          
#  body_html           :text          
#  created_at          :datetime      
#  updated_at          :datetime      
#  published_at        :datetime      
#  counter_cache       :boolean(1)    default(true)
#  type                :string(255)   
#  allow_comments      :boolean(1)    
#  status              :integer(11)   default(0), not null
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_unit_helper'

class ArticleTest < Test::Unit::TestCase
  fixtures :collections, :articles, :linkings, :users, :memberships
  
  def setup
    @model = Article
		@record_one = Article.find(1)
		@new_obj = {
			:parent_id => Article.find(:first).id,
		  :user_id=> User.find(:first).id,        
		  :title=>'My Favorite Game System',                
		  :excerpt=>"My Favorite Game System is the Atari2600",        
		  :body=>'My Favorite Game System is the Atari2600 because it contained the most awesome hardware eva.',           
		  :excerpt_html=>'<b>My Favorite Game System is the Atari2600</b>',   
		  :body_html=>'<b>My Favorite Game System is the Atari2600</b> because it contained the most awesome hardware eva.',                 
		  :allow_comments=>true,
		  :status=>0
		}
  end

  def test_create_article
    unit_create @model, @new_obj
  end

  def test_validations
    a = Article.create @new_obj.merge({:user_id=>nil,:title=>nil,:body=>nil})
    assert_equal false, a.valid?
    assert a.errors[:title], 'Article should require titel'
    assert a.errors[:user_id], 'Article should require user_id'
    assert a.errors[:body],'Article should require a body'
  end
  
  def test_destroy_article
    doomed = @model.find(1)
    @model.destroy(doomed.id)
    assert_raise(ActiveRecord::RecordNotFound) {@model.find(doomed.id)}
  end
  
  def test_destroy_article_shall_delete_associated_comments
    a = an_article({:allow_comments=>true})
    c = a_comment({:parent_id=>a.id})
    assert Comment.find(c.id)
    @model.destroy(a.id)
    assert_raise(ActiveRecord::RecordNotFound) {@model.find(a.id)}
    assert_raise(ActiveRecord::RecordNotFound) {Comment.find(c.id)}
  end
  def test_update_article
    @id = @model.find(:first).id
  	unit_update @model, @id, @new_obj
  end
  
  def test_shall_allow_tags
    a = an_article({:allow_comments=>true})
    assert a.valid?
    assert_equal a.tags.size, 0
    a.tag_with "Cool, Monkey, \"Ruby On Rails\""
    a = Article.find(a.id)
    assert_equal a.tags.size, 3
  end
  
  def test_article_shall_use_a_counter_cache
    a = an_article({:allow_comments=>true})
    assert_equal a.allow_comments, true
    assert_equal a.children_count, 0
    c = a_comment({:parent_id=>a.id})
    a = Article.find(a.id)
    assert_equal a.children_count, 1
  end
  
  def test_shall_allow_comments
    a = an_article({:allow_comments=>true})
    assert_equal a.allow_comments, true
    assert_equal a.comments.size, 0
    c = a_comment({:parent_id=>a.id})
    assert_equal c.class.to_s, "Comment"
    assert_equal Article.find(a.id).comments.size, 1
  end
  
  def test_shall_allow_articles_to_disallow_comments
    a = an_article({:allow_comments=>false})
    assert_equal a.allow_comments, false
    c = a_comment({:parent_id=>a.id})
    assert_equal false, c.valid?
  end
  
end
