class AdminController < ProtectedController; end
  require_dependency 'admin_controller/group_methods'
  require_dependency 'admin_controller/user_methods'
  require_dependency 'admin_controller/category_methods'
class AdminController
  include GroupMethods
  include UserMethods
  include CategoryMethods
  before_filter :admin_access_required
  
  def index
    redirect_to :action=>'dashboard'
  end
  
  def dashboard

  end
  
  protected
  def admin_access_required
    redirect_to :controller=>'account',:action=>'index' unless current_user.is_admin?
  end
end
