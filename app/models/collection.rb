# Schema as of Sun Sep 24 21:27:08 PDT 2006 (schema version 16)
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
#  permanent           :boolean(1)    
#

class Collection < ActiveRecord::Base
	belongs_to :user
  @@states = ['Pending', 'Denied', 'Approved']
  cattr_accessor :states
  def state
    self.class.states[self.state_id]
  end
  attr_protected :permanent
    
  BOOLEAN = [true,false] 
  before_destroy :dont_delete_permanent_collections
  
  def dont_delete_permanent_collections
    raise "You cannot delete this." if self.permanent
  end
end
