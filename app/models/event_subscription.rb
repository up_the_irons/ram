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
