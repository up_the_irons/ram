module AdminController::UserMethods
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
end