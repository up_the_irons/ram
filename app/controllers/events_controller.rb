class EventsController < ProtectedController
  include Sortable

  before_filter :admins_only
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
      @event.destroy
      list
    end
  end

  def show
    render :update do |page|
      page.toggle       "event_body_container_#{params[:id]}"
      page.replace_html "event_body_#{params[:id]}", @event.msg_body

      # Replace the onclick handler that got us here with a simple element toggler. We already have the msg
      # body loaded, so we don't need to call this action again.
      page << "$('a_href_#{params[:id]}').onclick = function() { $('event_body_container_#{params[:id]}').toggle(); return false }"
    end if @event
  end

  protected

  def find_single_event
    @event = Event.find(params[:id], :conditions => ["recipient_id = ?", current_user.id])
  end

  # Same code is in AdminController, let's DRY this up soon...
  def admins_only
    redirect_to :controller => 'account', :action => 'index' unless current_user && current_user.is_admin?
  end
end
