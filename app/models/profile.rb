# Schema as of Sat Sep 02 01:11:01 PDT 2006 (schema version 15)
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
#

# Schema as of Sat Jun 24 11:18:29 PDT 2006 (schema version 6)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  created_on          :datetime      
#  updated_on          :datetime      
#  bio                 :text          
#  address_line1       :string(255)   default()
#  address_line2       :string(255)   default()
#  city                :string(255)   default()
#  state               :string(255)   default()
#  country             :string(255)   default()
#  postal_code         :string(255)   default()
#  telephone           :string(255)   default()
#  fax                 :string(255)   default()
#


class Profile < ActiveRecord::Base
	belongs_to :user
end
