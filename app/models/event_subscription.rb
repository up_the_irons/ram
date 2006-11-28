# Schema as of Sun Nov 26 22:00:45 PST 2006 (schema version 2)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  event_trigger_id    :integer(11)   
#

#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class EventSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :event_trigger
end
