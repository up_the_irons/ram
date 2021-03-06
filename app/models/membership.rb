#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

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
