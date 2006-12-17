class JunkMail < ActiveRecord::Base
  is_collected :by => %w(readers)
end
