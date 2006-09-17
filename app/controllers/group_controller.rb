class GroupController < ProtectedController
  observer :group_observer
  
  def index
    list
  end

  def list
    #@group_pages, @groups = paginate :groups, :per_page => 10
    @group_pages, @groups = paginate_collection current_user.groups, :page => @params[:page]
    render :partial=>'group/list', :layout=>'application'
  end

  def show
   #@group = Group.find(params[:id])
   @group = find_in_users_groups params[:id]
   raise if @group.nil?
  rescue 
     redirect_to :controller=>'inbox'
     flash[:notice] = 'This group could not be found in your access list'
  end
end
