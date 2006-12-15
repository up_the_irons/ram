class Printing < ActiveRecord::Base
end
# Used to test Single Table Inheritance (STI)
class Book < Printing
  has_a_collection :for => %w(readers)
end

class Magazine < Printing
  has_a_collection :for => %w(readers)
end

class Paperback < Book
  
end

# Used to ensure more than just STI works
class JunkMail < ActiveRecord::Base
  has_a_collection :for => %w(readers)
end

class Letter < ActiveRecord::Base  
  has_a_collection :for => %w(readers)
end
