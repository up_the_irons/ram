class GroupController < ProtectedController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    #@group_pages, @groups = paginate :groups, :per_page => 10
    @group_pages, @groups = paginate_collection current_user.groups, :page => @params[:page]
  end

  def show
   #@group = Group.find(params[:id])
   @group = find_in_users_groups params[:id]
   render :text=>'Could not find this group in your account' if @group.nil?
  end

  def new
    @group = Group.new
  end

 # def create
 #   @group = Group.new(params[:group])
 #   if @group.save
 #     flash[:notice] = 'Group was successfully created.'
 #     redirect_to :action => 'list'
 #   else
 #     render :action => 'new'
 #   end
 # end
 #
 # def edit
 #   @group = find_in_users_groups params[:id]
 #   render :text=>'Could not find this group in your account' if @group.nil?
 # end
 #
 # def update
 #   @group = find_in_users_groups params[:id]
 #   if @group.update_attributes(params[:group])
 #     flash[:notice] = 'Group was successfully updated.'
 #     redirect_to :action => 'show', :id => @group
 #   else
 #     render :action => 'edit'
 #   end
 # end
 #
 # def destroy
 #   @group = find_in_users_groups params[:id]
 #   @group.destroy unless @group.nil?
 #   redirect_to :action => 'list'
 # end
  
end
