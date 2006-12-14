require File.join(File.dirname(__FILE__), 'abstract_unit')

class SubscribableTest < Test::Unit::TestCase

  def setup
    @nolan = a_reader({:name => 'nolan'})
    @make = a_magazine({:title => 'Make', :publisher => "O'rly?"})
    @catch22 = a_book({:title=>'Catch 22',:publisher => "Classics Press"})
    @oprahs_bookclub = a_book_club({:name => 'oprahs book club'})
  end
  
  # Test the readers associations instead of the magazine
  def test_collect_for
    assert @nolan.magazines.empty?
    assert @make.readers.empty?
    assert_difference @nolan.magazines, :size do
      assert @nolan.magazines << @make
    end
    
    # Prevent duplicate records
    assert_no_difference @nolan.magazines, :size do
      @nolan.magazines << @make
    end
    
    # test the other end of the has_many association
    assert @make.readers(true).include?(@nolan)
    assert_equal 1, @make.readers.size
    # don't allow duplicate records
    assert_no_difference @make.readers, :size do
      @make.readers << @nolan
    end
    # TODO
    # @nolan.bookclubs << @oprahs_bookclub
    # @catch22.bookclubs << @oprahs_bookclub
    # assert @oprahs_bookclub.readers.include?(@nolan)
    # assert @oprahs_bookclub.books.include?(@catch22)
  end

  # The collector should be able to dynamically segment their collections like:
  # @reader.books, @reader.magazines.
  def test_dynamic_polymorphic_associations
    assert @make.readers.empty?
    assert @catch22.readers.empty?
    @nolan.books << @catch22
    assert @nolan.books.include?(@catch22)
    
    # Check that STI classes work.
    assert_no_difference @nolan.books, :size do
      @nolan.magazines << @make
      assert @nolan.magazines.include?(@make)
    end

    # Check that non STI tables work.
    l = a_letter
    assert_difference @nolan.letters, :size do
      assert @nolan.letters << l
      assert @nolan.letters.include?(l)
    end
    assert l.readers.include?(@nolan)
    
    # Prevent duplicate records.
    assert_no_difference @nolan.magazines, :size do
       @nolan.magazines << @make
    end
    
    %w(readers).each do |assoc|
      assert_equal 1, @catch22.send(assoc.to_sym,true).size
      assert_equal 1, @make.send(assoc.to_sym,true).size
      assert @catch22.send(assoc.to_sym,true).include?(@nolan)
      assert @make.send(assoc.to_sym,true).include?(@nolan)
    end
    
    %w(books magazines).each do |assoc|
      assert_equal 1, @nolan.send(assoc.to_sym,true).size
    end
  end
  
  # Test the generic methods available to has_many associations.
  def test_has_many_methods
    
    # Reader#books (similar to Reader.find :all, :conditions => "book_id = #{id}")
    assert_equal [], @nolan.books
    @nolan.books << @catch22
    @nolan.magazines << @make
    
    # Reader#letters.empty? (similar to reader.letters.size == 0)
    assert @nolan.letters.empty?
    
    # Reader#letters<<
    l = a_letter
    @nolan.letters << l
    assert @nolan.letters(true).include?(l)
    
    # Reader#letters.size (similar to Letter.count "letter_id = #{id}")
    assert_equal 1, @nolan.letters.size
    assert @nolan.books(true).include?(@catch22), "Reader's books should include 'Catch 22'"
    assert @nolan.magazines(true).include?(@make), "Reader's magazines should include 'Make'"
    
    # TODO
    # Reader#books=
    
    # Reader#book_ids=
    
    # Reader#books.find (similar to Book.find(id, :conditions => "reader_id = #{id}"))
    assert_equal @catch22.id, @nolan.books.find(@catch22.id).id
    
    # Reader#books.build (similar to Book.new("reader_id" => id))
    assert @nolan.books.build({:title => 'foo'}).valid?
    
    # Reader#books.create (similar to b = Book.new("reader_id" => id); b.save; b)
    assert_difference @nolan.books, :size do
      created_book = @nolan.books.create({:title => 'foo_too'})
      assert @nolan.books.include?(created_book)
    end 
    
    # now delete the newly added records
    assert_difference @nolan.books(true), :size, -1 do
      # Reader#books.delete
      @nolan.books.delete @catch22
    end
    
    # Reader#books.clear
    assert !@nolan.books.empty?
    @nolan.books.clear
    assert @nolan.books.empty?
    
  end
  
  # Disallow records from storing the wrong association types.
  def test_prevent_association_mismatches
    assert !(@nolan.books << JunkMail.create)
  end
  
  # Route the object to the correct association magically.
  def test_magically_reroute_associations
    assert_difference @nolan.books, :size do
      @nolan.magazines << a_book
    end
  end
          
  protected
  def a_reader(opts = {})
    o = { :name => "Reader: #{Time.now.to_s}"}.merge(opts)
    Reader.create(o)
  end
  
  def a_book_club(opts = {})
    o = { :name => "Book Club: #{Time.now.to_s}"}.merge(opts)
    Bookclub.create(o)
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
