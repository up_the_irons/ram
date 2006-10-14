class AccountController < ProtectedController
  observer :user_observer
  cache_sweeper :change_sweeper
  def index
    redirect_to :action=>'my_profile' if logged_in? and return
  end

  
  def directory
    #TODO scope this directory to the group list
		 @user_pages, @users = paginate :users, :per_page => 10
	end


  def login
    redirect_to :controller=>'inbox' and return if current_user
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if current_user
      if current_user.account_active?
        after_login
        redirect_back_or_default(:controller => '/inbox', :action => 'index')
        
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
    #TODO scope this request so that people don't see profiles that they should not.
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
  
  def avatar
    #TODO :Scope this call.
    @avatar = Avatar.find(params[:id])
    send_data @avatar.data, :filename => @avatar.filename, :type => @avatar.content_type, :disposition => 'inline'
  end
  
  
  def edit
    @user    = current_user
    @person  = @user.person 
    @profile = @user.profile

    if request.post? && @user
      @avatar  = @user.avatar ||= Avatar.new
      
      #used to prevent users from forging the request to reset attributes we want to protect.
      safe_hash = {:email=>''}
      safe_hash[:email] = params[:user][:email] if params[:user] && params[:user][:email]
      @avatar = create_avatar(@user.id,params[:avatar][:uploaded_data]) unless params[:avatar].nil?
      
      if @user.update_attributes(safe_hash) && @user.person.update_attributes(params[:person]) &&  @user.profile.update_attributes(params[:profile])
        flash[:notice] = "Your changes have been saved."
      else
        flash[:notice] = "There was an error saving your information."
      end 
    end
  end
  
  
  def logout
    self.current_user = nil
    flash[:grail] = "You have been logged out."
    redirect_back_or_default(:controller => '/account', :action => 'login')
    session[:nil]
  end
  
  
  def login_as
    self.current_user = User.find(params[:user_id])
    if current_user.account_active?
      after_login
      render :update do |page|
        page.redirect_to :controller=>'inbox'
      end
    else
      render :update do |page|
        page.call "grail.notify",{:type=>"confirm",:subject=>'Could not log you in',:body=>"#{current_user.account_status}."}
        page.replace_html 'page_flash', current_user.account_status
      end
    self.current_user = nil
    end
  end
  
  def toggle_menu
    if session[:view][:expand_menu]
      session[:view][:expand_menu] = false
    else
      session[:view][:expand_menu] = true
    end
    render :nothing =>true
  end
  
  def display_as
    session[:asset_display] = params[:id] unless params[:id].nil?
  end
  
  protected 
  def after_login
    flash[:grail]  = "Welcome #{current_user.login}!"
    current_user.last_login_at = Time.now
    current_user.save
    session[:folio] = []
    session[:view]={:expand_menu=>true}
    
    session[:category_tree] = current_user.categories_as_tree
  end
end
