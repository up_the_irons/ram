# Schema as of Sun Oct 22 21:28:20 PDT 2006 (schema version 19)
#
#  id                  :integer(11)   not null
#  record_id           :integer(11)   
#  record_type         :string(255)   
#  event               :string(255)   
#  user_id             :integer(11)   
#  created_at          :datetime      
#

class Change < ActiveRecord::Base
end
