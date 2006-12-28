#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
# 
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class AdminController < ProtectedController; end
require_dependency 'collection_methods'

class AdminController
  include Sortable
  include EnlightenObservers
  layout 'admin'
  observer :group_observer, :change_observer, :category_observer

  volatile = [:destroy_group, :create_group, :update_group, :destroy_category, :create_category, :update_category]
  before_filter :admin_access_required
  
  verify :method => :post, :only =>volatile, :redirect_to => { :action => :dashboard }

  sortable :dashboard
  
  def index
    redirect_to :action=>'dashboard'
  end
  
  def categories
    list_collection({:table=>'categories'})
  end
  
  def groups
    list_collection({:table=>'groups'})
  end
  
  def show_category
    show_collection({:table=>'categories'})
  end
  
  def show_group
    show_collection({:table=>'groups'})
  end
  
  def edit_group
      edit_collection({:table=>'groups', :many_associations=>['users','categories'], :required_associations=>['user_ids']})
  end
  
  def edit_category
    edit_collection({:table=>'categories', :many_associations=>['groups'], :required_associations=>['group_ids']})
  end
  
  # A group is not destroyed, it's disbanded!
  def disband_group
    destroy_collection({:table=>'groups', :on_success=>'You disbanded the group.'})
  rescue
    flash[:notice] = "Could not find group."
    redirect_to :action=>'groups'
  end
  
  def destroy_category
    destroy_collection({:table=>'categories'})
  rescue
    flash[:notice] = "Could not find category."
    redirect_to :action=>'categories'
  end
  
  # The user methods do not use the collection_methods module
  def users
    @user_pages, @users = paginate :users, :per_page => 10
    render 'admin/users'
  end
  
  def deleted_users
    @user_pages, @users  = paginate_collection(User.find(:all, :conditions => "deleted_at IS NOT NULL", :include_deleted => true))
    render 'admin/users'
  end
  
  def destroy_user
    @user = User.find(params[:id])
    raise unless @user
    redirect_to :action=>'show_user', :id=>@user.id and return false unless request.post?
    raise unless @user.destroy
    flash[:notice] = "You deleted #{@user.login}"
    redirect_to :action=>'users'
  rescue
    flash[:notice] = "Could not find user."
    redirect_to :action=>'users'
  end
  
  def edit_user
    @user    = User.find(params[:id],:include_deleted=>true)
    @person  = @user.person
    @profile = @user.profile
    if request.post? && @user
      @avatar  = @user.avatar ||= Avatar.new
      @avatar = create_avatar(@user.id,params[:avatar][:uploaded_data]) unless params[:avatar].nil?
      if params[:user] && params[:user][:group_ids]
        groups = []
        params[:user][:group_ids].map{ | g | groups << Group.find(g)}
        params[:user].delete('group_ids')
        @user.groups = groups
        @user = User.find(@user.id) # Force the reload.  TODO: Rework this so you don't have to find the record twice.
      end
      # TODO: Find a way to make this more dry.
      if @user.update_attributes(params[:user]) && @user.person.update_attributes(params[:person]) &&  @user.profile.update_attributes(params[:profile])
        @profile = @user.profile
        @person  = @user.person 
        flash[:notice] = "Your changes have been saved."
      else
        @profile = @user.profile
        @person  = @user.person
        flash[:notice] = "There was an error saving your information."
      end 
    end
  end
  
  def show_user
    @user = User.find_by_id_or_login(params[:id])
    render :partial => 'account/profile',
           :locals  => { :user => @user},
           :layout  =>'application' unless @user.nil?
  end
    
  def dashboard
    @events = Event.find_all_by_recipient_id(current_user.id, :order => @order)
  end
  
  def settings
      # There should only be one setting record for the application
      @settings = $APPLICATION_SETTINGS
      return false unless request.post?
      
      if @settings.update_attributes(params[:settings])
        flash[:notice] = "Your changes have been saved."
        $APPLICATION_SETTINGS = Setting.find(@settings.id)
      end
  end

  def event_subscriptions
    if request.post?
      EventSubscription.transaction do
        EventSubscription.delete_all("user_id = #{current_user.id}")

        params[:event_subscriptions].each do |code|
          EventSubscription.create(:user_id => current_user.id, :event_trigger => EventTrigger.find_by_code(code))
        end
      end 
    end

    @subscribed_to = current_user.event_subscriptions.reload.map { |o| o.event_trigger.code }
  end

  protected

  def admin_access_required
    unless current_user.is_admin?
      flash[:notice] = "Access Denied"
      redirect_to :controller => 'inbox' 
    end
  end
end
