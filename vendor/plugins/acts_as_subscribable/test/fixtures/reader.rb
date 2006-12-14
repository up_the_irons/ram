class Person < ActiveRecord::Base
end

# FIXME Adding this class to has_a_collection prodcues a load error.
# The reason this happens is that the bookclub has many readers and the readers have many bookclubs
# and neighter can load without the other, yet neither can properly load because one will have to come in front of the other.
# maybe it is possible to add the has_many association after the class has been initialized.
class Bookclub < ActiveRecord::Base
  # acts_as_subscribable :of => %w(books), :for=>["readers"]
end

class Reader < Person
  # acts_as_subscribable :subscribe_to => %w(books magazines letters)
  acts_as_subscribable :of => %w(books magazines letters)
end
  
