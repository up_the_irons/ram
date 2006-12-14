require File.dirname(__FILE__) + '/../test_helper'

class FeedTest < Test::Unit::TestCase
  fixtures :collections, :feeds, :users, :subscriptions, :changes, :assets, :articles, :settings

  def setup
    @model_attributes={:name=>Time.now.to_s, :url=>'http://developer.apple.com/rss/adcheadlines.rss',:is_local=>false, :local_path=>'/feed/category/8'}
  end
  
  def test_create
    # Feed with remote path
    assert_difference Feed,:count do
      f = a_feed(@model_attributes)
      @model_attributes.each_pair do |k,v|
        assert_equal f[k], v
      end
    end
    
    # Feed with local path
    assert_difference Feed,:count do
      @model_attributes.merge!({:name=>"Foo!",:url=>'http://www.google.com',:is_local=>true, :local_path=>'feed/category/5'})
      c = a_feed(@model_attributes)
      @model_attributes.each_pair do |k,v|
        assert_equal c[k], v
        assert c.is_local?
      end
    end
  end
  
  def test_local_feed
    cat = users(:administrator).categories[0]
    change = a_change({"record_type"=>cat.class.class_name, "event"=>"UPDATE", "user_id"=>users(:administrator).id, "record_id"=>cat.id, "created_at"=>Time.now.to_s})
    assert_equal(cat.changes[0].id, change.id) # Change one thing about the category so that there is atleast one feed item.
    feed = a_feed @model_attributes.merge({:is_local=>true,:local_path=>"/feed/category/#{cat.id}"})
    result = RSS::Parser.parse(feed.data, false)
    
    assert_equal feed.name, result.channel.title
    assert_equal cat.description, result.channel.description
    # Ensure the change is now an item of the feed.
    assert_equal change.name, result.channel.items[0].title
    assert_equal change.description, result.channel.items[0].description
  end
  
  def test_uniqueness_of_attributes
    f = a_feed(@model_attributes)
    f2 = Feed.create({:name=>f.name, :url=>f.url,:local_path=>false})
    
    assert f2.errors.on(:name)
    f2.update_attribute :name, "unique name #{Time.now.to_s}"
    f2.save    
    assert f2.valid?
  end
  
  def test_add_and_remove_subscriber
    administrator = User.find(1)
    
    assert_equal 1, User.find(administrator.id).feeds.size
    assert_equal 1, Subscription.find(:all).size
    assert_unchanged administrator.feeds, :size do
      assert_no_difference Subscription, :count do
        @feed = Feed.create(@model_attributes)
      end
    end
    assert_equal 0, @feed.users.size
    
    # Add 
    users = User.find(:all)
    assert_difference Subscription, :count, users.size do
      assert_difference @feed.users, :size, users.size do
        users.each do |user|
          @feed.users << user
        end
      end
    end
    assert_equal 2, User.find(administrator.id).feeds.size

    # Remove
    assert_difference @feed.users, :size, -1 do
      @feed.users.delete users(:administrator)
    end
    
    assert_equal 1, User.find(administrator.id).feeds.size
    
    # Remove the rest
    @feed.users.clear
  end
  
  def test_validations
    # All these fields are required for a feed without them filled out will produce errors
    required_fields = [:name]
    f = Feed.create
    assert_no_difference Feed, :count do
      assert !f.valid?
      assert_equal 1, f.errors.size
      required_fields.each{|k| assert !f.errors.on(k).empty? }
    end
    
    # Now validate the format of the url
    assert_no_difference Feed, :count do
      f.name ="foo"
      f.is_local = false
      f.url = "dsfsdfsdfsdfdsf" #bad url
      assert !f.save
      assert_equal 1, f.errors.size
    end
    
    # Now fix everything so it saves
    assert_difference Feed, :count do
      f.url = @model_attributes[:url]
      assert f.save
    end
  end
  
  def test_update
    f = Feed.create(@model_attributes);
    assert f.valid?
    @model_attributes.each_pair do |k,v|
      assert_equal f[k], v
    end
    new_attributes = { :name=>"fooo", :url=>"http://images.apple.com/downloads/macosx/home/recent.rss" }
    f.update_attributes(new_attributes)
    
    new_attributes.each_pair do |k,v|
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
