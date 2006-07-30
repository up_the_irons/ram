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
    @user = User.find_by_id_or_login(params[:id])

    render :partial=>'account/profile',
      :locals=>{:user=> @user},
      :layout=>'application' unless @user.nil?
  end
  
  def show_group
    @group       = Group.find_by_id_or_login(params[:id])
    @non_members = @group.non_members.map{ |m| [m.login, m.id] }
  end

  def group_add_member
    @group       = Group.find_by_id_or_login(params[:id])
    @group.users << User.find(params[:user_id])
    @non_members = @group.non_members.map{ |m| [m.login, m.id] }
 
    render :update do |page|
      page.replace_html 'group_members',     :partial => 'group_members'
      page.replace_html 'available_members', :partial => 'add_group_member_dropdown'
      page.visual_effect :highlight, 'group_members'
    end
  end

  def group_remove_member
    @group       = Group.find_by_id_or_login(params[:id])

    # Why the heck doesn't this work?!  This might be an ActiveRecord bug; I tried working with this in console and AR
    # *does* delete the record from its array cache, but the Membership remains in the DB. This doesn't seem right, so
    # I instead delete the Membership manually below.  It's the only way I found to truly get rid of the user from 
    # this group.
    #
    #@group.users.delete(User.find(params[:user_id]))
    
    Membership.find_by_user_id_and_collection_id(params[:user_id], @group.id).destroy
    @group.users(true) # Reload

    @non_members = @group.non_members.map{ |m| [m.login, m.id] }

    render :update do |page|
      page.replace_html 'group_members',     :partial => 'group_members'
      page.replace_html 'available_members', :partial => 'add_group_member_dropdown'
    end
  end
  
  protected
  def admin_access_required
    redirect_to :controller=>'account',:action=>'index' unless current_user.is_admin?
  end
end
