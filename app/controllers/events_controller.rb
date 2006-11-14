#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class EventsController < ProtectedController
  before_filter :find_single_event, :only => [:delete, :show]

  sortable      :list, :delete

  def list
    @events = Event.find_all_by_recipient_id(current_user.id, :order => @order)

    respond_to do |wants|
      wants.html
      wants.js do
        render :update do |page|
          page.replace_html 'events_table', :partial => 'list'
        end
      end
    end
  end

  def delete
    if @event
      render :update do |page|
        page.replace_html "message_#{params[:id]}", ""
        page.replace_html "message_body_#{params[:id]}", ""
      end if @event.destroy
    end
  end

  def show
    @event[:author] = "unknown"
    @event[:author] = User.find(@event.sender_id).full_name if @event.sender_id
    @event[:typeof] = "event"

    render :update do |page|
      page.toggle       "message_body_container_#{params[:id]}"
      page.replace_html "message_body_#{params[:id]}", :partial => 'shared/post', :locals => { :post => @event }

      # Replace the onclick handler that got us here with a simple element toggler. We already have the msg
      # body loaded, so we don't need to call this action again.
      page << "$(Content.cache.push($('message_body_container_#{params[:id]}')))"
    end if @event
  end

  protected

  def find_single_event
    @event = Event.find(params[:id], :conditions => ["recipient_id = ?", current_user.id])
  end
end
