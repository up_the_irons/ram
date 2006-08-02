class AccountController < ProtectedController

  def index
    redirect_to(:action => 'signup') unless logged_in? or User.count > 0
  end
  
  def directory
    #localize this directory to the group list
		 @user_pages, @users = paginate :users, :per_page => 10
	end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if current_user
      if current_user.account_active?
        flash[:notice] = "Logged in Successfully"
        redirect_back_or_default(:controller => '/account', :action => 'index')
        current_user.last_login_at = Time.now
        current_user.save
      else
        flash[:error] = current_user.account_status
        session[:user] = self.current_user = nil
      end
    else
      flash[:error] = "An account could not be found with that username or password"
    end
  end

  def signup
    @user = User.new(params[:user])
    return unless request.post?
    if @user.save
      redirect_back_or_default(:controller => '/account', :action => 'index')
      flash[:notice] = "Thanks for signing up!"
    end
  end
  
  def profile
    if params[:id].to_s.match(/^\d+$/)
        @user = User.find(params[:id])
      else
        @user = User.find_by_login(params[:id])
      end
      render :partial=>'account/profile',
    	  :locals=>{:user=> @user},
    		:layout=>'application' unless @user.nil?
  end
  
  def my_profile
    @user = User.find(current_user.id)
    render :partial=>'account/profile',
  	  :locals=>{:user=> @user},
  		:layout=>'application' unless @user.nil?
  end
  
  def logout
    self.current_user = nil
    
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => '/account', :action => 'login')
    session[:nil]
  end
  
  def login_as
    self.current_user = User.find(params[:user_id])
    if current_user.account_active?
      render :update do |page|
        page.redirect_to :controller=>'category', :action=>'list'
      end
    else
      render :update do |page|
        page.replace_html 'page_flash', current_user.account_status
      end
    end
  end
end
