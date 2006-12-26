#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
# 
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class AccountController < ProtectedController
  include EnlightenObservers

  observer :user_observer, :change_observer

  def index
    redirect_to :action=>'my_profile' unless logged_in?.nil? and return
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
  
  def forgot_password
    return unless request.post?
    unless params[:email] && params[:login]
      flash[:notice] =  "Both login and email are required to reset your account."
      redirect_to :action=> 'login' and return false
    end
    
    if user = User.find_by_email_and_login(params[:email],params[:login])
      @new_password = random_password
      user.password = user.password_confirmation =  @new_password
      user.save_without_validation
      UserNotifier.deliver_reset_password(user, @new_password)

      flash[:notice] = "Your details have been sent to #{params[:email]}"
    else
      flash[:notice] =  "We could not find an account with that login or username."
    end
    redirect_to :action=> 'login'
  end
  
  def profile
    # TODO: Scope this request so that people don't see profiles that they should not.
    if params[:id].to_s.match(/^\d+$/)
        @user = User.find(params[:id])
    else
        @user = User.find_by_login(params[:id])
    end
    render :partial => 'account/profile',
           :locals  => { :user => @user },
           :layout  => 'application' unless @user.nil?
  end
  
  def my_profile
    @user = User.find(current_user.id)
    render :partial=>'account/profile',
      :locals=>{:user=> @user},
      :layout=>'application' unless @user.nil?
  end

  def avatar
    # TODO: Scope this call.
    @avatar = Avatar.find(params[:id])
    send_data @avatar.data, :filename => @avatar.filename, :type => @avatar.content_type, :disposition => 'inline'
  end
  
  def edit
    @user    = current_user
    @person  = @user.person 
    @profile = @user.profile
    render :action=>"edit" and return false unless request.post? && @user
    
    # Used to prevent users from forging the request to reset attributes we want to protect.
    safe_hash = {}
    safe_hash[:email] = params[:user][:email] if params[:user] && params[:user][:email]
    
    if params[:user] && params[:user][:password] && params[:user][:password] != "**********"
      safe_hash[:password] = params[:user][:password]
      safe_hash[:password_confirmation] = params[:user][:password_confirmation]
    end
    
    # Only create the avatar if a file was selected and RMagick is available.
    # TODO if no avatar is available then use a default icon.
    if params[:avatar] && params[:avatar][:uploaded_data].size > 0 && $APPLICATION_SETTINGS.preferences[:rmagick?]
      @avatar = create_avatar(@user.id,params[:avatar][:uploaded_data])
    end
      
    if @user.update_attributes(safe_hash) && @user.person.update_attributes(params[:person]) &&  @user.profile.update_attributes(params[:profile])
      flash[:notice] = "Your changes have been saved."
    else
      flash[:notice] = "There was an error saving your information."
    end 

  end
  
  def logout
    self.current_user = nil
    flash[:grail] = "You have been logged out."
    redirect_back_or_default(:controller => '/account', :action => 'login')
    session[:nil]
  end
  
  def login_as
    redirect_to :action=>'login' and return false unless RAILS_ENV == 'development' 
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
    render :nothing =>true
  end

  protected 

  def random_password( len = 20 )
    chars = (("a".."z").to_a + ("1".."9").to_a )- %w(i o 0 1 l 0)
    newpass = Array.new(len, '').collect{chars[rand(chars.size)]}.join
  end

  def after_login
    flash[:grail]  = "Welcome #{current_user.login}!"
    current_user.last_login_at = Time.now
    current_user.save
    session[:briefcase] = []
    session[:view]={:expand_menu=>true}
    
    session[:category_tree] = current_user.categories_as_tree
  end
end
