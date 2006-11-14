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
#  record_id           :integer(11)   
#  record_type         :string(255)   
#  event               :string(255)   
#  user_id             :integer(11)   
#  created_at          :datetime      
#

class Change < ActiveRecord::Base
  def name
    "#{record_type} #{event}"
  end
  
  def description
    "#{User.find(user_id).login} #{event} #{record_type.constantize.find(record_id).name} on #{created_at}"
  end
end
