# Schema as of Thu Sep 28 14:11:12 PDT 2006 (schema version 17)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  collection_id       :integer(11)   
#  collection_type     :string(255)   
#  state_id            :integer(11)   default(0)
#  created_at          :datetime      
#

# Schema as of Sat Jun 24 11:18:29 PDT 2006 (schema version 6)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  collection_id       :integer(11)   
#  collection_type     :string(255)   
#  state_id            :integer(11)   default(0)
#  created_at          :datetime      
#


class Membership < ActiveRecord::Base
  belongs_to :user,  :foreign_key => 'user_id'
  belongs_to :group, :foreign_key => 'collection_id', :class_name => 'Group',
                     :conditions  => "#{table_name}.collection_type = 'Group'",
                     :include     => :memberships
                     
  @@states = ['Pending', 'Denied', 'Approved'].freeze
  cattr_accessor :states
  
  def state
    Membership.states[self.state_id]
  end
  
  validates_uniqueness_of :user_id, :scope => 'collection_id'

#  validates_each :user_id, :on => :create do |record,attr,value|
#    if record.group.user_id == value
#      record.errors.add attr, "cannot be the group owner"
#    end
#  end
    
end
