# Schema as of Sat Jun 24 11:18:29 PDT 2006 (schema version 6)
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

# Schema as of Sun Jun 04 11:25:18 PDT 2006 (schema version 6)
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
