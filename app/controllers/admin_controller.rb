class AdminController < ProtectedController; end
  require_dependency 'admin_controller/group_methods'
  require_dependency 'admin_controller/user_methods'
  require_dependency 'admin_controller/category_methods'
class AdminController
  include GroupMethods
  include UserMethods
  include CategoryMethods
  include Sortable

  #observer :group_observer
  before_filter :admin_access_required
  
  verify :method => :post, :only => [ :destroy_group, :create_group, :update_group, :destroy_category, :create_category, :update_category ],
          :redirect_to => { :action => :dashboard }

  sortable :dashboard
          
  def index
    redirect_to :action=>'dashboard'
  end
  
  def dashboard
    @events = Event.find_all_by_recipient_id(current_user.id, :order => @order)
  end
  
  protected
  def admin_access_required
    flash[:notice] = "Access Denied"
    redirect_to :controller=>'inbox' unless current_user.is_admin?
  end
end
