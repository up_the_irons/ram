class AdminController < ProtectedController; end
require_dependency 'collection_methods'

class AdminController
  include Sortable
  
  observer :group_observer
  volatile = [:destroy_group, :create_group, :update_group, :destroy_category, :create_category, :update_category ]
  cache_sweeper :change_sweeper
  before_filter :admin_access_required
  
  verify :method => :post, :only =>volatile, :redirect_to => { :action => :dashboard }

  sortable :dashboard
  
  #sortable       :show
  #paging_with_db :show
  
       
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
    edit_collection({:table=>'groups', :many_associations=>['users','categories']})
  end
  
  
  def edit_category
    edit_collection({:table=>'categories', :many_associations=>['groups']})
  end
  
  
  #A group is not destroyed its disbanded!
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
  
  #the user methods do not use the collection_methods module
  
  def users
    @user_pages, @users = paginate :users, :per_page => 10
    render 'admin/users'
  end
  def edit_user
    @user    = User.find(params[:id])
    @person  = @user.person
    @profile = @user.profile
    if request.post? && @user
      if params[:user][:group_ids]
        groups = []
        params[:user][:group_ids].map{ | g | groups << Group.find(g)}
        params[:user].delete('group_ids')
        @user.groups = groups
        @user = User.find(@user.id) #force the reload TODO: rework this so you don't have to find the record twice.
      end
      #TODO: Find a way to make this more dry.
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
    #render 'account/edit'
  end
  
  def show_user
    @user = User.find_by_id_or_login(params[:id])
    render :partial=>'account/profile',
      :locals=>{:user=> @user},
      :layout=>'application' unless @user.nil?
  end
    
    
  def dashboard
    @events = Event.find_all_by_recipient_id(current_user.id, :order => @order)
  end

  protected
  def admin_access_required
    unless current_user.is_admin?
      flash[:notice] = "Access Denied"
      redirect_to :controller=>'inbox' 
    end
  end
  
end
