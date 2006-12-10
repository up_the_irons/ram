require File.join(File.dirname(__FILE__), 'abstract_unit')

class SubscribableTest < Test::Unit::TestCase

  def setup
    @nolan = a_reader({:name => 'nolan'})
    @make = a_magazine({:title => 'Make', :publisher => "O'rly?"})
    @catch22 = a_book({:title=>'Catch 22',:publisher => "Classics Press"})
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
    assert @nolan.books.include?(@catch22), "Reader's books should include 'Catch 22'"
    assert @nolan.magazines.include?(@make), "Reader's magazines should include 'Make'"
  end
  
  def test_push_on_dynamic_associations
    r = a_reader
    # These are STI
    b = a_book
    m = a_magazine
    # This is not
    l = a_letter
    r.books << b
    r.magazines << m
    
    # Single Table Interitance tests
    assert r.books.include?(b), "Reader's books should include '#{b.title}'."
    
    # Ensure only the books are counted not other subscription types
    assert_equal 1, r.books.size, "Reader's books should include just one book."
    
    # Ensure that books not belonging to any subscription are not picked up as well.
    b2 = a_book
    assert_equal 1, r.books.size, "Reader's books should include just one book."
    
    # Non STI
    assert r.letters << l
    assert r.letters.include?(l)
    assert_equal 1, r.letters.size
  end
  
  def test_prevent_association_mismatches
    assert !(@nolan.books << JunkMail.create)
  end
  
  # Route the object to the correct association magically.
  def test_magically_reroute_associations
   assert_difference @nolan.books, :size do
     @nolan.magazines << a_book
   end
  end
  
  def test_delete_through_dynamic_associations
    assert @nolan.books << @catch22
    assert 1, @nolan.books.size
  end
          
  protected
  def a_reader(opts = {})
    o = { :name => "Reader: #{Time.now.to_s}"}.merge(opts)
    Reader.create(o)
  end
  
  def a_letter(opts = {})
    o = { :subject => "Letter: #{Time.now.to_s}", :body => "I'm in ur testz"}.merge(opts)
    Letter.create(o)
  end
  
  def a_magazine(opts={})
    o = {:title => "Magazine: #{Time.now.to_s}", :publisher => "O'rly?"}.merge(opts)
    Magazine.create(o)
  end
  
  def a_book(opts={})
    o = {:title => "Book: #{Time.now.to_s}", :publisher => "beats me"}.merge(opts)
    Book.create(o)
  end
end
