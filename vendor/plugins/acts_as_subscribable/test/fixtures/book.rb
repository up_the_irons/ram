class Printings < ActiveRecord::Base
  
end

class Book < Printings
  acts_as_subscribable
end

class Magazine < Printings
  acts_as_subscribable
end

class Paperback < Book
  acts_as_subscribable
end