#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

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
