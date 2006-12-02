require File.join(File.dirname(__FILE__), 'abstract_unit')

class SubscribableTest < Test::Unit::TestCase
  def setup
    @nolan = a_reader({:name => 'nolan'})
    @make = a_magazine({:title => 'Make', :publisher=>"O'rly?"})
    @catch22 = a_book
  end
  
  # Test the magazines assoications 
  def test_add_and_remove_subscriber
    assert @make.subscribers.empty?
    
    assert_difference @make.subscribers, :size do
      @make.subscribers << @nolan
    end
    
    assert_difference @make.subscribers, :size, -1 do
      @make.subscribers.unsubscribe @nolan
    end
  end
  
  def test_unsubscribe_all
    cat_fancy = a_magazine
    n = 5
    # Add a bunch of readers to "Cat Fancy"
    assert_difference cat_fancy.subscribers, :size, n do
      n.times do |r|
        cat_fancy.subscribers << a_reader({:name=>r})
      end
    end
    
    # Unsubscribe them all and send a message to the publishers of Cat Fancy. Power to the people!
    assert_difference cat_fancy.subscribers, :size, -n do
      cat_fancy.subscribers.unsubscribe_all
    end
  end
  
  def test_prevent_duplicate_subscriptions
    @make.subscribers << @nolan
    assert @make.subscribers.include?(@nolan)
    assert_no_difference @make.subscribers, :size do
      @make.subscribers << @nolan
    end
  end
  
  # Test the readers associations instead of the magazine
  def test_subscribed_to
    assert @nolan.subscriptions.empty?
    assert_difference @nolan.subscriptions, :size do
      assert @nolan.subscriptions << @make
    end
    
    # Prevent duplicate subscriptions
    assert_no_difference @nolan.subscriptions, :size do
      @nolan.subscriptions << @make
    end
  end
  
  def test_polymorphic_subscriptions
    assert @nolan.subscriptions.empty?
    assert_difference @nolan.subscriptions, :size, 2 do
      @nolan.subscriptions << @catch22
      @nolan.subscriptions << @make
    end
    assert @catch22.subscribers.include?(@nolan)
    assert @make.subscribers.include?(@nolan)
  end
  
  # The subscriber should be able to dynamically segment their subscriptions like:
  # @reader.books, @reader.magazines.
  def test_dynamic_access_to_subscribed_classes
    assert @nolan.subscriptions.empty?
    assert_difference @nolan.subscriptions, :size, 2 do
      @nolan.subscriptions << @catch22
      @nolan.subscriptions << @make
    end
    assert @nolan.books.include?(@catch22)
    assert @nolan.magazines.include?(@make)
  end
  
  def test_push_on_dynamic_associations
    r = a_reader
    b = a_book
    r.books << b
    # TODO
    # assert r.books.include?(b)
  end
        
  protected
  def a_reader(opts = {})
    o = { :name => 'nolan'}.merge(opts)
    Reader.create(o)
  end
  
  def a_magazine(opts={})
    o = {:title => 'Make', :publisher => "O'rly?"}
    Magazine.create(o)
  end
  
  def a_book(opts={})
    o = {:title => 'Catch22', :publisher => "beats me"}
    Book.create(o)
  end
end