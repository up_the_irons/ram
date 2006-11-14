#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class EventMailer < ActionMailer::Base

  def notification(recipient_email, event)
    @subject    = "RAM Event Notification: #{event.subject}"
    @body       = { :event => event }
    @recipients = recipient_email
    @from       = ''
    @sent_on    = Time.now
    @headers    = {}
  end
end
