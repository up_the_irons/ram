class Letter < ActiveRecord::Base  
  is_collected :by => %w(readers)
end