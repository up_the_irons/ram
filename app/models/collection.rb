#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

# Schema as of Fri Oct 27 20:31:51 PDT 2006 (schema version 22)
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
#  created_at          :datetime      
#  updated_at          :datetime      
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
    self.class.states[state_id]
  end
    
  BOOLEAN = [true, false] 

  def tags=(str)
    if str == ''
      Tagging.destroy_all("taggable_id = #{id} AND taggable_type = '#{self.class.name}'")
    else
      arr = str.split(",").uniq
      self.tag_with arr.map { |a| a }.join(",") unless arr.empty?
    end
  end

end
