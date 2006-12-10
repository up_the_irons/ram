class Printing < ActiveRecord::Base
end
# Used to test Single Table Inheritance (STI)
class Book < Printing
  acts_as_subscribable
end

class Magazine < Printing
  acts_as_subscribable
end

class Paperback < Book
  acts_as_subscribable
end

# Used to ensure more than just STI works
class JunkMail < ActiveRecord::Base
  acts_as_subscribable
end

class Letter < ActiveRecord::Base  
  acts_as_subscribable
end
