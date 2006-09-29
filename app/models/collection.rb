# Schema as of Thu Sep 28 14:11:12 PDT 2006 (schema version 17)
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
  attr_protected :permanent

  before_destroy :dont_delete_permanent_collections
  
  def dont_delete_permanent_collections
    raise "You cannot delete this." if self.permanent
  end
  

  def state
    self.class.states[self.state_id]
  end
    
  BOOLEAN = [true, false] 

  def tags=(str)
    arr = str.split(",").uniq
    self.tag_with arr.map { |a| a }.join(",") unless arr.empty?
  end

end
