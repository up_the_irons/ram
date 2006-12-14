class Printing < ActiveRecord::Base
end
# Used to test Single Table Inheritance (STI)
class Book < Printing
  acts_as_subscribable :for => %w(readers)
end

class Magazine < Printing
  acts_as_subscribable :for => %w(readers)
end

class Paperback < Book
  
end

# Used to ensure more than just STI works
class JunkMail < ActiveRecord::Base
  acts_as_subscribable :for => %w(readers)
end

class Letter < ActiveRecord::Base  
  acts_as_subscribable :for => %w(readers)
end
