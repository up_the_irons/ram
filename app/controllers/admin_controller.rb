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
      if !@group.users(true).include?(current_user) and !@group.new_record?
        flash[:notice] = "You are no longer can edit \"#{@group.name}\""
        redirect_to :action => "dashboard" and return false 
      end
      redirect_to(:action => "edit_group", :id => @group.id) unless params[:id] || @group.new_record?
  end
  
  def edit_category
    edit_collection({:table=>'categories', :many_associations=>['groups'], :required_associations=>['group_ids']})
    if !@category.groups(true).map{|g| g.id}.include?($APPLICATION_SETTINGS.admin_group_id) and !@category.new_record?
      flash[:notice] = "You are no longer can edit \"#{@category.name}\""
      redirect_to :action => "dashboard" and return false
    end
    redirect_to(:action => "edit_category", :id => @category.id) unless params[:id] || @category.new_record?
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
    @user = User.new 
    @profile = Profile.new
    @person = Person.new
    return unless request.post? || params[:id]
    
    if params[:id]
      @user = User.find(params[:id],:include_deleted=>true) 
      @person  = @user.person
      @profile = @user.profile
    end
    return unless request.post?
    
    @avatar  = @user.avatar ||= Avatar.new
    @avatar = create_avatar(@user.id,params[:avatar][:uploaded_data]) unless params[:avatar].nil?
    if params[:user] && params[:user][:group_ids]
      @groups = []
      params[:user][:group_ids].map{ | g | @groups << Group.find(g)}
      params[:user].delete('group_ids')
    end
    
    if @user.update_attributes(params[:user]) && @user.person.update_attributes(params[:person]) &&  @user.profile.update_attributes(params[:profile])
      @profile = @user.profile
      @person  = @user.person 
      flash[:notice] = "Your changes have been saved."
      @user.groups= @groups if @groups
      @user.groups(true)
    else
      @profile = @user.profile
      @person  = @user.person
      flash[:notice] = "There was an error saving your information."
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
