# Schema as of Sun Oct 22 21:28:20 PDT 2006 (schema version 19)
#
#  id                  :integer(11)   not null
#  url                 :string(255)   
#  name                :string(255)   
#

class Feed < ActiveRecord::Base
  acts_as_subscribable
  
  validates_presence_of :name, :url
  validates_format_of :url, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix
end
