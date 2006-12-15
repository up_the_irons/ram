require File.join(File.dirname(__FILE__), 'abstract_unit')

class HasACollection < Test::Unit::TestCase

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
    assert_add_to_collection @nolan, :magazines, @make
    
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
    assert_add_to_collection @nolan, :books, @catch22
    assert @catch22.readers(true).include?(@nolan)
    
    # Check that STI classes work.
    assert_no_difference @nolan.books, :size do
      @nolan.magazines << @make
      assert @nolan.magazines.include?(@make)
      assert @make.readers(true).include?(@nolan)
    end

    # Check that non STI tables work.
    l = a_letter
    assert_add_to_collection @nolan, :letters, l
    assert l.readers.include?(@nolan)
    
    # Prevent duplicate records.
    assert_no_difference @make.readers, :size do
      assert_no_difference @nolan.magazines, :size do
        @nolan.magazines << @make
      end
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
  
  # Test the generic methods available to has_many associations for both the collector and the collectee.
  def test_has_many_array_accessors
    
    # Reader#books (similar to Book.find :all, :conditions => "reader_id = #{id}")
    # Reader#books.size (similar to Book.count "reader_id = #{id}")
    # Reader#books.empty? (similar to @reader.books.size == 0)
    # Reader#books<<
    # Reader#books.include?
    # Reader#books.find (similar to Book.find(id, :conditions => "reader_id = #{id}"))
    assert @nolan.books.empty?
    assert_add_to_collection @nolan, :books, @catch22
    assert_equal @catch22.id, @nolan.books.find(@catch22.id).id
    
    # Magazine#readers.size (similar to Reader.count "book_id = #{id}")
    # Magazine#readers (similar to Readers.find :all, :conditions => "book_id = #{id}")
    # Magazine#readers.empty? (similar to @book.readers.size == 0)
    # Magazine#readers<<
    # Magazine#readers.include?
    # Magazine#readers.find (similar to Reader.find(id, :conditions => "magazine_id = #{id}"))
    
    assert @make.readers.empty?
    assert_add_to_collection @make, :readers, @nolan
    assert_equal @nolan.id, @make.readers.find(@nolan.id).id
 end
 
 # Build does not work like the normal has_many association does because there is no "belongs_to" assocation, therefore
 # this record will be instanciated but no join association will be created. Use Record#objects.build if possible or
 # explicitly add it back to the parent object after calling build i.e. @record.objects << @built_object.
 def test_build
    # Reader#books.build (similar to Book.new("reader_id" => id))
    assert @nolan.books.build({:title => 'foo'}).valid?
    # Book#readers.build (similar to Reader.new("book_id" => id))
    assert @make.readers.build({:name => 'foo'}).valid?
 end
 
 def test_create
    # Reader#books.create (similar to b = Book.new("reader_id" => id); b.save; b)
    assert_difference @nolan.books(true), :size do
      created_book = @nolan.books.create({:title => 'foo_too'})
      assert @nolan.books.include?(created_book)
    end 
    
    # Book#readers.create (similar to r = Reader.new("reader_id" => id); r.save; r)
    assert_difference @catch22.readers(true), :size do
      created_reader = @catch22.readers.create({:name => 'Mr. Foo'})
      assert @catch22.readers.include?(created_reader)
    end
  end
  
  def test_delete
    assert_add_to_collection @nolan, :books, @catch22
    assert_difference @nolan.books(true), :size, -1 do
      # Reader#books.delete
      @nolan.books.delete @catch22
    end
    
    assert_add_to_collection @make, :readers, @nolan
    assert_difference @make.readers(true), :size, -1 do
      # Book#readers.delete
      @make.readers.delete @nolan
    end
  end
  
  def test_clear
    assert_add_to_collection @nolan, :books, @catch22
    # Reader#books.clear
    assert !@nolan.books.empty?
    @nolan.books.clear
    assert @nolan.books.empty?

    assert_add_to_collection @make, :readers, @nolan
    # Magazine#readers.clear
    assert !@make.readers.empty?
    @make.readers.clear
    assert @make.readers.empty?
  end
  
  def test_assocaition_attr_writer
    # Reader#books=
    @books = []
    @readers = []
    5.times do 
      @books << a_book
      @readers << a_reader
    end
    assert_equal 5, @books.size 
    @nolan.books= @books
    @books.each do | book |
      assert @nolan.books(true).include?(book)
    end
    
    assert_equal 5, @readers.size 
    @make.readers= @readers
    @readers.each do | reader |
      assert @make.readers(true).include?(reader)
    end
  end
  
  def test_association_ids_writer
    # easy way to set up the records in the state we need.
    test_assocaition_attr_writer
    @book_ids = []
    @reader_ids = []
    5.times do 
      @book_ids << a_book.id
      @reader_ids << a_reader.id
    end
    assert_equal 5, @reader_ids.size
    @make.reader_ids= @reader_ids
    @readers.each do | reader |
      assert !@make.readers(true).include?(reader)
    end
    @reader_ids.each do | id |
      assert @make.readers(true).map{| record | record.id }.include?(id)
    end
    
    assert_equal 5, @book_ids.size
    @nolan.book_ids= @book_ids
    @books.each do | book |
      assert !@nolan.books(true).include?(book)
    end
    @book_ids.each do | id |
      assert @nolan.books(true).map{| record | record.id }.include?(id)
    end
  end
  
  # Disallow records from storing the wrong association types.
  def test_prevent_association_mismatches
    assert !(@nolan.books << JunkMail.create)
    assert !(@make.readers << @catch22)
  end
  
  # Route the object to the correct association magically.
  def test_magically_reroute_associations
    assert_difference @nolan.books, :size do
      @nolan.magazines << a_book
    end
  end
          
  protected
  def assert_add_to_collection(record, collection, object)
    assert_difference record.send(collection,true), :size do
      record.send(collection,true) << object
    end
    assert record.send(collection,true).include?(object)
  end
  
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
