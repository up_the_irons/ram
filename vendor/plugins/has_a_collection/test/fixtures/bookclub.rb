class Bookclub < ActiveRecord::Base
  has_a_collection :of => %w(books)
  is_collected :by=>["readers"]
end