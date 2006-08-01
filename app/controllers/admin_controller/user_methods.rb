module AdminController::UserMethods
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
end