class Reader < Person
  has_a_collection :of => %w(magazines books letters bookclubs)
end
  
