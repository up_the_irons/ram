class AdminController < ProtectedController
  before_filter :admin_access_required
  
  def index
    redirect_to :action=>'dashboard'
  end
  
  def dashboard

  end
  
  def list_groups
    	 @group_pages, @groups = paginate :groups, :per_page => 10
    	 render 'admin/list_groups'
  end
  
  def list_categories
    	 @category_pages, @categories = paginate :categories, :per_page => 10
    	 render 'admin/list_categories'
  end
  
  def list_users
    	 @user_pages, @users = paginate :users, :per_page => 10
    	 render 'admin/list_users'
  end
  
  def show_user
     if params[:id].to_s.match(/^\d+$/)
        @user = User.find(params[:id])
      else
        @user = User.find_by_login(params[:id])
      end
      render :partial=>'account/profile',
    	  :locals=>{:user=> @user},
    		:layout=>'application' unless @user.nil?
  end
  
  def show_group
    if params[:id].to_s.match(/^\d+$/)
      @group = Group.find(params[:id])
    else
      @group = Group.find_by_login(params[:id])
    end
    @non_members = (User.find(:all) - @group.users).map{|m| [m.login,m.id]}
  end

  def group_add_member
    if params[:id].to_s.match(/^\d+$/)
      @group = Group.find(params[:id])
    else
      @group = Group.find_by_login(params[:id])
    end

    @group.users << User.find(params[:user_id])
 
    render :update do |page|
      page.replace_html 'group_members', :partial => 'group_members'
      page.visual_effect :highlight, 'group_members'
    end
  end
  
  protected
  def admin_access_required
    redirect_to :controller=>'account',:action=>'index' unless current_user.is_admin?
  end
end
