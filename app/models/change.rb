#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class Change < ActiveRecord::Base
  def name
    "#{record_type} #{event}"
  end
  
  def description
    "#{User.find(user_id).login} #{event} #{record_type.constantize.find(record_id).name} on #{created_at}"
  end
end
