class Reader < Person
  has_collection :of => %w(magazines books letters bookclubs)
end
  
