# Schema as of Thu Sep 28 14:11:12 PDT 2006 (schema version 17)
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
