# Schema as of Sat Sep 02 01:11:01 PDT 2006 (schema version 15)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#  description         :text          
#  public              :boolean(1)    default(true)
#  user_id             :integer(11)   
#  type                :string(255)   
#  state_id            :integer(11)   
#  parent_id           :integer(11)   
#  counter_cache       :boolean(1)    default(true)
#

# Schema as of Wed Aug 30 23:30:45 PDT 2006 (schema version 15)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#  description         :text          
#  public              :boolean(1)    default(true)
#  user_id             :integer(11)   
#  type                :string(255)   
#  state_id            :integer(11)   
#  parent_id           :integer(11)   
#  counter_cache       :boolean(1)    default(true)
#

class Collection < ActiveRecord::Base
	belongs_to :user
  @@states = ['Pending', 'Denied', 'Approved']
  cattr_accessor :states
  def state
    self.class.states[self.state_id]
  end
  
  BOOLEAN = [true,false] 

end
