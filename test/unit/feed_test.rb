require File.dirname(__FILE__) + '/../test_helper'
class FeedTest < Test::Unit::TestCase
  fixtures :feeds, :users

  def setup
    @model_attributes={:name=>Time.now.to_s, :url=>'http://www.foo.com'}
  end
  
  
  def test_create
    f = a_feed(@model_attributes)
    @model_attributes.each_pair do |k,v|
      assert_equal f[k], v
    end
  end
  
  def test_add_and_remove_subscriber
    f = Feed.create(@model_attributes)
    assert_equal 0, f.subscribers.size
    
    quentin = users(:quentin)
    assert_equal 0, User.find(quentin.id).feeds.size

    #add 
    users = User.find(:all)
    assert_difference f.subscribers, :size, users.size do
      users.each do|user|
        f.subscribers << user
      end
    end
    assert_equal 1, User.find(quentin.id).feeds.size

    #remove
    assert_difference f.subscribers, :size, -1 do
      f.unsubscribe users(:quentin)
    end
    assert_equal 0, User.find(quentin.id).feeds.size
    
    #remove the rest
    f.unsubscribe_all
    
  end
  
  
  def test_validations
     #all these fields are required for a feed without them filled out will produce errors
     required_fields = [:name,:url]
     f = Feed.create
     assert_no_difference Feed, :count do
       assert !f.valid?
       assert_equal 3, f.errors.size
       required_fields.each{|k| assert !f.errors.on(k).empty? }
     end
     
     #now validate the format of the url
     assert_no_difference Feed, :count do
      f.name ="foo"
      f.url = "dsfsdfsdfsdfdsf" #bad url
      assert !f.save
      assert_equal 1, f.errors.size
     end
     
     #now fix everything so it saves
     assert_difference Feed, :count do
       f.url = @model_attributes[:url]
       assert f.save
     end
   end
  
  
  def test_update
    f = Feed.create(@model_attributes);
    assert f.valid?
    @model_attributes.each_pair do|k,v|
      assert_equal f[k], v
    end
    new_attributes = {"name"=>"fooo", "url"=>"http://www.yahoo.com"}
    f.update_attributes(new_attributes)
    
    new_attributes.each_pair do|k,v|
      assert_equal f[k], v
    end
  end
  
  
  def test_destroy
    f = a_feed
    assert f.valid?
    f.destroy
    assert_raise(ActiveRecord::RecordNotFound){Feed.find(f.id)}
  end
 
  
end
