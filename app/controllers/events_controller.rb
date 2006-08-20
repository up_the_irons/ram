class EventsController < ProtectedController
  include Sortable

  before_filter :admins_only
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
    @event = Event.find(params[:id], :conditions => ["recipient_id = ?", current_user.id])

    if @event
      @event.destroy

      list
    end
  end

  # Same code is in AdminController, let's DRY this up soon...
  def admins_only
    redirect_to :controller => 'account', :action => 'index' unless current_user && current_user.is_admin?
  end
end