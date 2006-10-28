# Schema as of Fri Oct 27 20:31:51 PDT 2006 (schema version 22)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  created_on          :datetime      
#  updated_on          :datetime      
#  bio                 :text          
#  address_line1       :string(255)   
#  address_line2       :string(255)   
#  city                :string(255)   
#  state               :string(255)   
#  country             :string(255)   
#  postal_code         :string(255)   
#  telephone           :string(255)   
#  fax                 :string(255)   
#  job_title           :string(255)   default()
#  company             :string(255)   default()
#

# Schema as of Fri Oct 27 16:48:28 PDT 2006 (schema version 21)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  created_on          :datetime      
#  updated_on          :datetime      
#  bio                 :text          
#  address_line1       :string(255)   
#  address_line2       :string(255)   
#  city                :string(255)   
#  state               :string(255)   
#  country             :string(255)   
#  postal_code         :string(255)   
#  telephone           :string(255)   
#  fax                 :string(255)   
#  job_title           :string(255)   default()
#  company             :string(255)   default()
#


class Profile < ActiveRecord::Base
	belongs_to :user
end
