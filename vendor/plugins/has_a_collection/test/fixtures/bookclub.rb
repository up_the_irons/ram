class Bookclub < ActiveRecord::Base
  has_collection :of => %w(books), :table_name => 'members', :class_column => "member", :association_column => "offering", :before_add =>'increment_subscribers_count'
  is_collected :by=>["readers"], :table_name => 'members', :class_column => "offering", :association_column => "member"
  
  def foo2
    puts "foo2"
  end

  def increment_subscribers_count
    puts "increment subscribers"
  end
  
  def increment_offerings_count
    
  end

end