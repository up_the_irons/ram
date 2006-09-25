# Schema as of Sun Sep 24 21:27:08 PDT 2006 (schema version 16)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  first_name          :string(200)   default()
#  last_name           :string(200)   default()
#  gender              :integer(11)   default(0), not null
#  date_of_birth       :date          
#  created_on          :datetime      
#  updated_on          :datetime      
#

# Schema as of Tue Sep 05 23:25:32 PDT 2006 (schema version 15)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  first_name          :string(200)   default()
#  last_name           :string(200)   default()
#  gender              :integer(11)   default(0), not null
#  date_of_birth       :date          
#  created_on          :datetime      
#  updated_on          :datetime      
#

class Person < ActiveRecord::Base

belongs_to :user
  GENDERS = [
            ['Unspecified',0],
            ['Male',1],
            ['Female',2]
            ].freeze
	def full_name
		first_name + ' ' + last_name
	end
	def name
    first_name + ' ' + last_name      
  end
end
