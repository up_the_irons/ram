class AdminController < ProtectedController; end
  require_dependency 'collection_methods'
  require_dependency 'admin_controller/group_methods'
  require_dependency 'admin_controller/user_methods'
  require_dependency 'admin_controller/category_methods'
class AdminController
  include GroupMethods
  include UserMethods
  include CategoryMethods
  include Sortable
  
  observer :group_observer
  before_filter :admin_access_required
  
  verify :method => :post, :only => [ :destroy_group, :create_group, :update_group, :destroy_category, :create_category, :update_category ],
          :redirect_to => { :action => :dashboard }

  sortable :dashboard
       
  def index
    redirect_to :action=>'dashboard'
  end
  
  def categories
    list_collection('categories')
  end
  
  def groups
    list_collection('groups')
  end
  
  def show_category
    show_collection('categories')
  end
  
  def show_group
    show_collection('groups')
  end
  
  def edit_group
    edit_collection('groups','users')
  end
  
  def edit_category
    edit_collection('categories','groups')
  end
  
  #A group is not destroyed its disbanded!
  def disband_group
    destroy_collection('groups',{:on_success=>'You disbanded the group.'})
  rescue
    flash[:notice] = "Could not find group."
    redirect_to :action=>'groups'
  end
  
  def destroy_category
    destroy_collection('categories')
  rescue
    flash[:notice] = "Could not find category."
    redirect_to :action=>'categories'
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
