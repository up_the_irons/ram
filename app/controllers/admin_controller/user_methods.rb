module AdminController::UserMethods
  def users
     @user_pages, @users = paginate :users, :per_page => 10
     render 'admin/users'
   end
   def edit
    render :text=>'todo'
   end

   def show_user
     @user = User.find_by_id_or_login(params[:id])

     render :partial=>'account/profile',
       :locals=>{:user=> @user},
       :layout=>'application' unless @user.nil?
   end
end