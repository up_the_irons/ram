# Used to test Single Table Inheritance (STI)
class Book < Printing
  is_collected :by=> %w(readers bookclubs)
end
